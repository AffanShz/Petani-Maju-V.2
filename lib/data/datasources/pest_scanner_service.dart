import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PestScannerService {
  final String _baseUrl = dotenv.env['MODEL_TOMATO'] ?? '';

  Future<Map<String, dynamic>> predict(String imageUrl) async {
    try {
      debugPrint('PestScannerService: Starting prediction for URL: $imageUrl');
      
      final Uri url = Uri.parse('$_baseUrl/predict');
      debugPrint('PestScannerService: POST to $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'image_url': imageUrl
        }),
      ).timeout(const Duration(seconds: 45));

      debugPrint('PestScannerService: Status Code ${response.statusCode}');
      debugPrint('PestScannerService: Raw Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'label': data['label'] ?? 'Tidak Diketahui',
          'confidence': (data['confidence'] ?? 0.0) / 100.0, // Backend returns percentage (e.g. 98.45)
        };
      } else {
        throw _handleError(response);
      }
    } on SocketException {
      throw Exception('Masalah koneksi internet. Silakan periksa jaringan Anda.');
    } on http.ClientException catch (e) {
      throw Exception('Kesalahan pada client HTTP: ${e.message}');
    } catch (e) {
      debugPrint('PestScannerService Exception: $e');
      rethrow;
    }
  }

  Exception _handleError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        return Exception('Model Error: ${data['error']}');
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 404:
        return Exception('Endpoint model tidak ditemukan (404). Periksa konfigurasi URL di .env.');
      case 500:
        return Exception('Server model mengalami gangguan (500). Silakan coba lagi nanti.');
      case 503:
        return Exception('Model sedang dalam proses inisialisasi atau sedang sibuk (503).');
      default:
        return Exception('Gagal menghubungi model AI (Status: ${response.statusCode})');
    }
  }
}
