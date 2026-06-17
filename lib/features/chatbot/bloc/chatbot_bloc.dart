import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:petani_maju/data/models/chat_message.dart';
import 'package:petani_maju/data/repositories/chatbot_repository.dart';

part 'chatbot_event.dart';
part 'chatbot_state.dart';

class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final ChatbotRepository _chatbotRepository;

  ChatbotBloc({required ChatbotRepository chatbotRepository})
      : _chatbotRepository = chatbotRepository,
        super(const ChatbotInitial()) {
    on<SendMessage>(_onSendMessage);
    on<ResetChat>(_onResetChat);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatbotState> emit,
  ) async {
    final sanitized = _chatbotRepository.sanitizeInput(event.text);

    if (sanitized.isEmpty) {
      return;
    }

    final currentMessages = state is ChatbotLoaded
        ? List<ChatMessage>.from((state as ChatbotLoaded).messages)
        : <ChatMessage>[];

    currentMessages.add(ChatMessage(
      role: MessageRole.user,
      content: sanitized,
      timestamp: DateTime.now(),
    ));
    emit(ChatbotLoaded(messages: List.from(currentMessages), isStreaming: true));

    final botTimestamp = DateTime.now();
    currentMessages.add(ChatMessage(
      role: MessageRole.bot,
      content: '',
      timestamp: botTimestamp,
      isStreaming: true,
    ));
    final botIndex = currentMessages.length - 1;
    emit(ChatbotLoaded(messages: List.from(currentMessages), isStreaming: true));

    String accumulatedText = '';

    try {
      final stream = _chatbotRepository.sendMessage(
        userText: sanitized,
        currentWeather: event.currentWeather,
      );

      await for (final token in stream) {
        accumulatedText += token;
        currentMessages[botIndex] = ChatMessage(
          role: MessageRole.bot,
          content: accumulatedText,
          timestamp: botTimestamp,
          isStreaming: true,
        );
        emit(ChatbotLoaded(
          messages: List.from(currentMessages),
          isStreaming: true,
        ));
      }

      currentMessages[botIndex] = ChatMessage(
        role: MessageRole.bot,
        content: accumulatedText,
        timestamp: botTimestamp,
        isStreaming: false,
      );
      emit(ChatbotLoaded(
        messages: List.from(currentMessages),
        isStreaming: false,
      ));
    } catch (e) {
      debugPrint('ChatbotBloc Error: $e');
      currentMessages[botIndex] = ChatMessage(
        role: MessageRole.bot,
        content: accumulatedText.isNotEmpty
            ? accumulatedText
            : 'Maaf, terjadi kesalahan. Silakan coba lagi.',
        timestamp: botTimestamp,
        isStreaming: false,
      );
      emit(ChatbotError(
        messages: List.from(currentMessages),
        error: e.toString(),
      ));
    }
  }

  void _onResetChat(ResetChat event, Emitter<ChatbotState> emit) {
    _chatbotRepository.resetSession();
    emit(const ChatbotInitial());
  }
}
