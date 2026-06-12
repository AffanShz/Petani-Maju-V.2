import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotService {
  final String apiKey;
  late final GenerativeModel _model;
  ChatSession? _chatSession;

  ChatbotService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  void initSession({required String systemPrompt}) {
    _chatSession = _model.startChat(
      history: [
        Content.model([TextPart(systemPrompt)]),
      ],
    );
  }

  void resetSession({required String systemPrompt}) {
    initSession(systemPrompt: systemPrompt);
  }

  Stream<String> sendMessageStream(String prompt) async* {
    if (_chatSession == null) {
      throw StateError('ChatSession belum diinisialisasi. Panggil initSession() dulu.');
    }

    final responseStream = _chatSession!.sendMessageStream(
      Content.text(prompt),
    );

    await for (final chunk in responseStream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  bool get isReady => _chatSession != null;
}
