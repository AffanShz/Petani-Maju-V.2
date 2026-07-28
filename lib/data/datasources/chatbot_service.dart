import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String apiKey;
  final List<Map<String, dynamic>> _history = [];

  static const String _model = 'gemini-3.5-flash';
  static const String _apiBase = 'https://generativelanguage.googleapis.com/v1';

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
              'Mengerti. Saya Asisten Tani, siap membantu pertanyaan seputar pertanian.'
        }
      ]
    });
  }

  void resetSession({required String systemPrompt}) {
    initSession(systemPrompt: systemPrompt);
  }

  static const int _maxHistoryTurns = 20; // user+model pairs

  Stream<String> sendMessageStream(String prompt) async* {
    _history.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ]
    });

    // Keep system seed (2 entries) + last N turns to avoid context overflow
    if (_history.length > 2 + _maxHistoryTurns * 2) {
      _history.removeRange(2, _history.length - _maxHistoryTurns * 2);
    }

    final url = Uri.parse(
      '$_apiBase/models/$_model:streamGenerateContent?alt=sse&key=$apiKey',
    );

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = json.encode({'contents': _history});

    final client = http.Client();
    String accumulatedText = '';

    try {
      final response = await client.send(request);

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
        }      }

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
