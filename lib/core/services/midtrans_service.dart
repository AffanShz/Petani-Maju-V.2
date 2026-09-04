import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:petani_maju/core/constants/env_config.dart';

enum PaymentStatus {
  success,
  pending,
  failed,
  unknown,
}

class MidtransTransactionResult {
  final String orderId;
  final String? token;
  final String redirectUrl;
  final bool isLiveSandbox;
  final String? errorMessage;

  MidtransTransactionResult({
    required this.orderId,
    this.token,
    required this.redirectUrl,
    required this.isLiveSandbox,
    this.errorMessage,
  });
}

class MidtransService {
  static final MidtransService _instance = MidtransService._internal();
  factory MidtransService() => _instance;
  MidtransService._internal();

  static const String _sandboxSnapUrl =
      'https://app.sandbox.midtrans.com/snap/v1/transactions';
  static const String _sandboxStatusUrl =
      'https://api.sandbox.midtrans.com/v2';

  // Menyimpan status transaksi mock agar status awal selalu "pending"
  final Map<String, PaymentStatus> _mockTransactionStatuses = {};

  /// Cek apakah Server Key Midtrans sudah dikonfigurasi dengan benar di secrets.json
  ///
  /// Dashboard sandbox Midtrans menerbitkan server key berawalan 'Mid-server-'
  /// (tanpa 'SB-'), sedangkan sebagian akun lama memakai 'SB-Mid-server-'.
  /// Keduanya harus diterima, kalau tidak app diam-diam jatuh ke mock gateway
  /// walaupun key-nya sudah benar.
  bool get isServerKeyConfigured {
    final key = EnvConfig.midtransServerKey;
    return key.isNotEmpty &&
        !key.contains('YOUR_SANDBOX') &&
        (key.startsWith('Mid-server-') || key.startsWith('SB-Mid-server-'));
  }

  /// Membuat transaksi Snap di Midtrans Sandbox API
  Future<MidtransTransactionResult> createTransaction({
    required String planName,
    required int amount,
    String paymentMethod = 'qris',
    String? orderId,
    String customerName = 'Petani Unggul',
    String customerEmail = 'petani@petanimaju.id',
  }) async {
    // Generate Order ID yang valid untuk Midtrans (hanya huruf, angka, '-')
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanPlanCode = planName
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .padRight(3, 'X')
        .substring(0, 4);
    final generatedOrderId = orderId ?? 'PM-$cleanPlanCode-$timestamp';

    // Set initial status ke pending
    _mockTransactionStatuses[generatedOrderId] = PaymentStatus.pending;

    // Jika API Key belum diatur, gunakan Mock Sandbox
    if (!isServerKeyConfigured) {
      debugPrint(
          '[MidtransService] Server key belum diisi di secrets.json. Menggunakan Fallback Mock Gateway.');
      return MidtransTransactionResult(
        orderId: generatedOrderId,
        token: 'mock-token-$generatedOrderId',
        redirectUrl: _simulatorUrlFor(paymentMethod),
        isLiveSandbox: false,
      );
    }

    try {
      final serverKey = EnvConfig.midtransServerKey;
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

      // Pastikan nama item bersih dan tidak melebihi 50 karakter
      final cleanItemName = ('PRO $planName')
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .trim();
      final safeItemName = cleanItemName.length > 45
          ? cleanItemName.substring(0, 45)
          : cleanItemName;

      final payload = {
        'transaction_details': {
          'order_id': generatedOrderId,
          'gross_amount': amount,
        },
        'customer_details': {
          'first_name': customerName.isEmpty ? 'Petani' : customerName,
          'email': customerEmail.isEmpty ? 'petani@petanimaju.id' : customerEmail,
        },
        'item_details': [
          {
            'id': 'PRO-$cleanPlanCode',
            'price': amount,
            'quantity': 1,
            'name': safeItemName,
          }
        ],
        'enabled_payments': _enabledPaymentsFor(paymentMethod),
      };

      final response = await http.post(
        Uri.parse(_sandboxSnapUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final redirectUrl = data['redirect_url'] as String? ??
            'https://app.sandbox.midtrans.com/snap/v2/vtweb/$token';

        return MidtransTransactionResult(
          orderId: generatedOrderId,
          token: token,
          redirectUrl: redirectUrl,
          isLiveSandbox: true,
        );
      } else {
        debugPrint(
            '[MidtransService] Gagal create transaction: ${response.statusCode} - ${response.body}');
        return MidtransTransactionResult(
          orderId: generatedOrderId,
          redirectUrl: _simulatorUrlFor(paymentMethod),
          isLiveSandbox: false,
          errorMessage: 'Status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[MidtransService] Exception saat menghubungi Midtrans: $e');
      return MidtransTransactionResult(
        orderId: generatedOrderId,
        redirectUrl: _simulatorUrlFor(paymentMethod),
        isLiveSandbox: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Mengecek status transaksi saat ini ke API Midtrans
  Future<PaymentStatus> checkTransactionStatus(String orderId) async {
    if (!isServerKeyConfigured) {
      // Jika mode mock, kembalikan status mock (default: pending, kecuali jika sudah diubah sukses)
      return _mockTransactionStatuses[orderId] ?? PaymentStatus.pending;
    }

    try {
      final serverKey = EnvConfig.midtransServerKey;
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

      final response = await http.get(
        Uri.parse('$_sandboxStatusUrl/$orderId/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': basicAuth,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final txStatus = data['transaction_status'] as String?;
        final fraudStatus = data['fraud_status'] as String?;

        if (txStatus == 'capture') {
          return (fraudStatus == 'accept')
              ? PaymentStatus.success
              : PaymentStatus.pending;
        } else if (txStatus == 'settlement') {
          return PaymentStatus.success;
        } else if (txStatus == 'pending') {
          return PaymentStatus.pending;
        } else if (txStatus == 'deny' ||
            txStatus == 'cancel' ||
            txStatus == 'expire' ||
            txStatus == 'failure') {
          return PaymentStatus.failed;
        }
      } else if (response.statusCode == 404) {
        // Transaksi belum dibayar / belum memilih metode pembayaran di Snap
        return PaymentStatus.pending;
      }
    } catch (e) {
      debugPrint('[MidtransService] Error cek status: $e');
    }
    return PaymentStatus.pending;
  }

  /// Mengubah status mock transaksi menjadi success (untuk simulasi/demo)
  void setMockPaymentSuccess(String orderId) {
    _mockTransactionStatuses[orderId] = PaymentStatus.success;
  }

  /// Membuka link pembayaran Snap di Web Browser eksternal
  Future<bool> openPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[MidtransService] Gagal membuka URL pembayaran: $e');
    }
    return false;
  }

  /// Membuka Simulator Resmi Midtrans di Browser
  /// [type] bisa: 'qris', 'va_bca', 'va_bni', 'va_bri', 'va_mandiri', 'va_permata', 'va_cimb'
  Future<void> openMidtransSimulator({String type = 'qris'}) async {
    final url = _simulatorUrlFor(type);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _simulatorUrlFor(String type) {
    switch (type) {
      case 'va_bca':
        return 'https://simulator.sandbox.midtrans.com/bca/va/index';
      case 'va_bni':
        return 'https://simulator.sandbox.midtrans.com/bni/va/index';
      case 'va_bri':
        return 'https://simulator.sandbox.midtrans.com/bri/va/index';
      case 'va_mandiri':
        return 'https://simulator.sandbox.midtrans.com/openapi/va/index?bank=mandiri';
      case 'va_permata':
        return 'https://simulator.sandbox.midtrans.com/permata/va/index';
      case 'va':
        // Generic VA — arahkan ke BNI sebagai default
        return 'https://simulator.sandbox.midtrans.com/bni/va/index';
      case 'qris':
      default:
        return 'https://simulator.sandbox.midtrans.com/qris/index';
    }
  }

  List<String> _enabledPaymentsFor(String paymentMethod) {
    switch (paymentMethod) {
      case 'va':
        return ['bank_transfer'];
      case 'card':
        return ['credit_card'];
      case 'qris':
      default:
        return ['qris'];
    }
  }
}
