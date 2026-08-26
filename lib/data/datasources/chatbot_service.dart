import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:petani_maju/data/models/chat_message.dart';

class ChatbotService {
  final String apiKey;
  final List<Map<String, dynamic>> _history = [];

  static const List<String> _candidateModels = [
    'gemini-3.5-flash',
    'gemini-3.6-flash',
    'gemini-2.5-flash',
  ];

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

    String accumulatedText = '';
    Object? lastError;

    // Rantai fallback model untuk mengatasi HTTP 503 / 429 (High Demand)
    for (final model in _candidateModels) {
      final url = Uri.parse(
        '$_apiBase/models/$model:streamGenerateContent?alt=sse',
      );
      final client = http.Client();

      try {
        final request = http.Request('POST', url)
          ..headers['Content-Type'] = 'application/json'
          ..headers['x-goog-api-key'] = apiKey
          ..body = json.encode({'contents': _history});

        final response =
            await client.send(request).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          lastError = 'Gemini API error (${response.statusCode} - $model): $body';
          debugPrint('ChatbotService: Model $model returned status ${response.statusCode}. Trying next fallback model...');
          client.close();
          await Future.delayed(const Duration(milliseconds: 800));
          continue;
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
          client.close();
          return;
        }
      } catch (e) {
        lastError = e;
        debugPrint('ChatbotService: Request failed on model $model: $e');
        client.close();
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    if (accumulatedText.isEmpty) {
      throw Exception(lastError ??
          'Seluruh server model Gemini sedang sibuk karena trafik tinggi (503 High Demand). Silakan coba beberapa saat lagi.');
    }
  }

  bool get isReady => _history.isNotEmpty;
}

