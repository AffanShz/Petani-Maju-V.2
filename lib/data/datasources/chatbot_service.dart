import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:petani_maju/data/models/chat_message.dart';

class ChatbotService {
  final String apiKey;
  final List<Map<String, dynamic>> _history = [];

  static const String _model = 'gemini-3.5-flash';
  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1beta';

  ChatbotService({required this.apiKey});

  void initSession({required String systemPrompt}) {
    _history.clear();
    _history.add({
      'role': 'user',
      'parts': [
        {'text': systemPrompt}
      ]
    });
    _history.add({
      'role': 'model',
      'parts': [
        {
          'text':
              'Mengerti. Saya Asisten Tani, siap membantu seluruh pertanyaan dan analisis seputar pertanian dan perkebunan.'
        }
      ]
    });
  }

  void resetSession({required String systemPrompt}) {
    initSession(systemPrompt: systemPrompt);
  }

  void loadSessionHistory(List<ChatMessage> messages,
      {required String systemPrompt}) {
    initSession(systemPrompt: systemPrompt);
    for (final message in messages) {
      if (message.content.isEmpty) continue;
      _history.add({
        'role': message.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': message.content}
        ]
      });
    }
  }

  static const int _maxHistoryTurns = 15; // user+model pairs

  String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  Stream<String> sendMessageStream({
    required String prompt,
    File? imageFile,
  }) async* {
    final List<Map<String, dynamic>> userParts = [];

    final textPrompt = prompt.isNotEmpty
        ? prompt
        : (imageFile != null
            ? 'Tolong analisis gambar ini terkait pertanian atau perkebunan (nama tanaman, kondisi, hama/penyakit, atau rekomendasi perawatannya).'
            : 'Halo Asisten Tani.');

    userParts.add({'text': textPrompt});

    if (imageFile != null && await imageFile.exists()) {
      try {
        final bytes = await imageFile.readAsBytes();
        final mimeType = _getMimeType(imageFile.path);
        final base64Image = base64Encode(bytes);

        userParts.add({
          'inline_data': {
            'mime_type': mimeType,
            'data': base64Image,
          }
        });
      } catch (e) {
        debugPrint('ChatbotService: Failed to read image bytes: $e');
      }
    }

    _history.add({
      'role': 'user',
      'parts': userParts,
    });

    // Keep system seed (2 entries) + last N turns to avoid context overflow
    if (_history.length > 2 + _maxHistoryTurns * 2) {
      _history.removeRange(2, _history.length - _maxHistoryTurns * 2);
    }

    // API key dikirim via header x-goog-api-key, bukan di query string,
    // agar tidak bocor ke access-log server/CDN/proxy.
    final url = Uri.parse(
      '$_apiBase/models/$_model:streamGenerateContent?alt=sse',
    );

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..headers['x-goog-api-key'] = apiKey
      ..body = json.encode({'contents': _history});

    final client = http.Client();
    String accumulatedText = '';

    try {
      final response =
          await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Gemini API error ${response.statusCode}: $body');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data.isEmpty || data == '[DONE]') continue;

        try {
          final parsed = json.decode(data) as Map<String, dynamic>;
          final candidates = parsed['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                accumulatedText += text;
                yield text;
              }
            }
          }
        } catch (e) {
          // Log parse error tapi lanjutkan stream
          debugPrint('ChatbotService: SSE parse error: $e, data: $data');
        }
      }

      if (accumulatedText.isNotEmpty) {
        _history.add({
          'role': 'model',
          'parts': [
            {'text': accumulatedText}
          ]
        });
      }
    } finally {
      client.close();
    }
  }

  bool get isReady => _history.isNotEmpty;
}
