import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:petani_maju/core/constants/env_config.dart';

/// Service yang membungkus seluruh model AI HuggingFace Space:
/// - MODEL_PLANT  : deteksi jenis tanaman (Padi/Teh/Tomat) - multipart file
/// - MODEL_TOMATO : penyakit tomat - JSON {image_url}
/// - MODEL_RICE   : penyakit padi - multipart file (/predict/cnn)
/// - MODEL_TEA    : penyakit teh  - multipart file
///
/// Seluruh output dinormalisasi ke {label, confidence} dengan confidence 0..1.
class PestScannerService {
  // HuggingFace Spaces need up to 90s to wake from sleep (cold start)
  static const Duration _timeout = Duration(seconds: 120);

  // ─── Deteksi jenis tanaman (MODEL_PLANT) ──────────────────────────────────
  /// Mengembalikan {plant: 'Tomat'|'Padi'|'Teh', confidence: 0..1, accepted: bool}
  Future<Map<String, dynamic>> detectPlant(File image) async {
    final data = await _postMultipart(
      baseUrl: EnvConfig.modelPlantUrl,
      path: '/predict',
      image: image,
      tag: 'MODEL_PLANT',
    );

    return {
      'plant': (data['prediction'] ?? 'Tidak Diketahui').toString(),
      'confidence': _asDouble(data['confidence']), // sudah 0..1
      'accepted': data['accepted'] == true,
    };
  }

  // ─── Penyakit Tomat (MODEL_TOMATO) ────────────────────────────────────────
  /// Model tomat menerima image_url (JSON) dan mengembalikan confidence 0..100.
  Future<Map<String, dynamic>> predictTomato(String imageUrl) async {
    try {
      final Uri url = Uri.parse('${EnvConfig.modelTomatoUrl}/predict');
      debugPrint('PestScannerService[MODEL_TOMATO]: POST to $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'image_url': imageUrl}),
          )
          .timeout(_timeout);

      debugPrint(
          'PestScannerService[MODEL_TOMATO]: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'label': (data['label'] ?? 'Tidak Diketahui').toString(),
          'confidence': _asDouble(data['confidence']) / 100.0,
        };
      }
      throw _handleError(response);
    } on SocketException {
      throw Exception('Masalah koneksi internet. Silakan periksa jaringan Anda.');
    } on http.ClientException catch (e) {
      throw Exception('Kesalahan pada client HTTP: ${e.message}');
    } catch (e) {
      debugPrint('PestScannerService[MODEL_TOMATO] Exception: $e');
      rethrow;
    }
  }

  // ─── Penyakit Padi (MODEL_RICE) ───────────────────────────────────────────
  /// Endpoint /predict/cnn, multipart file, confidence sudah 0..1.
  Future<Map<String, dynamic>> predictRice(File image) async {
    final data = await _postMultipart(
      baseUrl: EnvConfig.modelRiceUrl,
      path: '/predict/cnn',
      image: image,
      tag: 'MODEL_RICE',
    );

    return {
      'label': (data['predicted_class'] ?? 'Tidak Diketahui').toString(),
      'confidence': _asDouble(data['confidence']), // sudah 0..1
    };
  }

  // ─── Penyakit Teh (MODEL_TEA) ─────────────────────────────────────────────
  /// Endpoint /predict, multipart file, confidence 0..100.
  Future<Map<String, dynamic>> predictTea(File image) async {
    final data = await _postMultipart(
      baseUrl: EnvConfig.modelTeaUrl,
      path: '/predict',
      image: image,
      tag: 'MODEL_TEA',
    );

    return {
      'label': (data['prediction'] ?? 'Tidak Diketahui').toString(),
      'confidence': _asDouble(data['confidence']) / 100.0,
    };
  }

  // ─── Helper multipart bersama ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _postMultipart({
    required String baseUrl,
    required String path,
    required File image,
    required String tag,
  }) async {
    try {
      final Uri url = Uri.parse('$baseUrl$path');
      debugPrint('PestScannerService[$tag]: POST (multipart) to $url');

      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final streamed = await request.send().timeout(_timeout);
      final response =
          await http.Response.fromStream(streamed).timeout(_timeout);

      debugPrint(
          'PestScannerService[$tag]: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw _handleError(response);
    } on SocketException {
      throw Exception('Masalah koneksi internet. Silakan periksa jaringan Anda.');
    } on http.ClientException catch (e) {
      throw Exception('Kesalahan pada client HTTP: ${e.message}');
    } catch (e) {
      debugPrint('PestScannerService[$tag] Exception: $e');
      rethrow;
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
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
        return Exception(
            'Endpoint model tidak ditemukan (404). Periksa konfigurasi URL di .env.');
      case 500:
        return Exception(
            'Server model mengalami gangguan (500). Silakan coba lagi nanti.');
      case 503:
        return Exception(
            'Model sedang dalam proses inisialisasi atau sedang sibuk (503).');
      default:
        return Exception(
            'Gagal menghubungi model AI (Status: ${response.statusCode})');
    }
  }
}
