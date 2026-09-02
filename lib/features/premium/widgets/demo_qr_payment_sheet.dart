import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:petani_maju/core/constants/colors.dart';

class DemoQrPaymentSheet extends StatefulWidget {
  final String planName;
  final String planPrice;
  final int amount;
  final String orderId;
  final int durationSeconds;
  final Future<void> Function() onConfirmPaid;

  const DemoQrPaymentSheet({
    super.key,
    required this.planName,
    required this.planPrice,
    required this.amount,
    required this.orderId,
    this.durationSeconds = 30,
    required this.onConfirmPaid,
  });

  @override
  State<DemoQrPaymentSheet> createState() => _DemoQrPaymentSheetState();
}

class _DemoQrPaymentSheetState extends State<DemoQrPaymentSheet> {
  late int _secondsLeft;
  Timer? _timer;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft -= 1;
        if (_secondsLeft == 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  String _buildQrPayload() {
    return 'PM-DEMO|${widget.orderId}|${widget.amount}|QRIS';
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _secondsLeft == 0 && !_isConfirming;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      // Layar pendek atau font sistem yang diperbesar bisa membuat isi sheet
      // lebih tinggi dari ruang yang tersedia, jadi biarkan bisa digulir.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pembayaran QRIS (Demo)',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Order: ${widget.orderId}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: QrImageView(
                data: _buildQrPayload(),
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _secondsLeft > 0
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _secondsLeft > 0
                        ? Icons.timer_outlined
                        : Icons.check_circle_rounded,
                    size: 18,
                    color: _secondsLeft > 0
                        ? const Color(0xFFE65100)
                        : AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _secondsLeft > 0
                          ? 'Tunggu: ${_formatTime(_secondsLeft)} sebelum bisa konfirmasi'
                          : 'QR siap! Silakan klik tombol di bawah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _secondsLeft > 0
                            ? const Color(0xFFE65100)
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _row('Paket', widget.planName),
                  const SizedBox(height: 6),
                  _row('Total', widget.planPrice, highlight: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canConfirm ? AppColors.primaryGreen : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _isConfirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  _isConfirming ? 'Memproses...' : 'Saya Sudah Bayar',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: canConfirm
                    ? () async {
                        setState(() => _isConfirming = true);
                        try {
                          await widget.onConfirmPaid();
                        } finally {
                          if (mounted) {
                            setState(() => _isConfirming = false);
                          }
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isConfirming ? null : () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        Text(
          v,
          style: TextStyle(
            fontSize: highlight ? 15 : 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: highlight ? AppColors.primaryGreen : Colors.black87,
          ),
        ),
      ],
    );
  }
}
