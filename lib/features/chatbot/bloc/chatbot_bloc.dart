import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:petani_maju/data/models/chat_message.dart';
import 'package:petani_maju/data/models/chat_session.dart';
import 'package:petani_maju/data/repositories/chatbot_repository.dart';

part 'chatbot_event.dart';
part 'chatbot_state.dart';

class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final ChatbotRepository _chatbotRepository;

  ChatbotBloc({required ChatbotRepository chatbotRepository})
      : _chatbotRepository = chatbotRepository,
        super(const ChatbotInitial()) {
    on<InitChatbot>(_onInitChatbot);
    on<SendMessage>(_onSendMessage);
    on<LoadChatSession>(_onLoadChatSession);
    on<StartNewChat>(_onStartNewChat);
    on<DeleteChatSession>(_onDeleteChatSession);
    on<ClearAllChatHistory>(_onClearAllChatHistory);
    on<ResetChat>(_onResetChat);

    add(const InitChatbot());
  }

  void _onInitChatbot(InitChatbot event, Emitter<ChatbotState> emit) {
    final sessions = _chatbotRepository.getChatSessions();
    final targetId = event.sessionId ?? _chatbotRepository.getLastActiveSessionId();

    if (targetId != null) {
      final session = _chatbotRepository.getChatSession(targetId);
      if (session != null && session.messages.isNotEmpty) {
        _chatbotRepository.loadSessionHistory(session.messages);
        emit(ChatbotLoaded(
          sessionId: session.id,
          messages: List.from(session.messages),
          isStreaming: false,
          sessions: sessions,
        ));
        return;
      }
    }

    emit(ChatbotInitial(sessions: sessions));
  }

  String _generateSessionTitle(String text, String? imagePath) {
    if (text.trim().isNotEmpty) {
      final clean = text.trim();
      return clean.length > 35 ? '${clean.substring(0, 32)}...' : clean;
    }
    if (imagePath != null) {
      return 'Analisis Gambar Tanaman';
    }
    return 'Konsultasi Pertanian';
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatbotState> emit,
  ) async {
    final sessions = _chatbotRepository.getChatSessions();

    // Validasi file gambar jika ada
    if (event.imagePath != null && event.imagePath!.isNotEmpty) {
      final validationError = _chatbotRepository.validateImageFile(File(event.imagePath!));
      if (validationError != null) {
        final currentMessages = state is ChatbotLoaded
            ? (state as ChatbotLoaded).messages
            : <ChatMessage>[];
        emit(ChatbotError(
          sessionId: state is ChatbotLoaded ? (state as ChatbotLoaded).sessionId : null,
          messages: currentMessages,
          error: validationError,
          sessions: sessions,
        ));
        return;
      }
    }

    final sanitized = _chatbotRepository.sanitizeInput(event.text);
    final hasImage = event.imagePath != null && event.imagePath!.isNotEmpty;

    if (sanitized.isEmpty && !hasImage) {
      final currentMessages = state is ChatbotLoaded
          ? List<ChatMessage>.from((state as ChatbotLoaded).messages)
          : <ChatMessage>[];
      emit(ChatbotLoaded(
        sessionId: state is ChatbotLoaded
            ? (state as ChatbotLoaded).sessionId
            : 'session_${DateTime.now().millisecondsSinceEpoch}',
        messages: currentMessages,
        isStreaming: false,
        sessions: sessions,
      ));
      return;
    }

    final sessionId = state is ChatbotLoaded && (state as ChatbotLoaded).sessionId.isNotEmpty
        ? (state as ChatbotLoaded).sessionId
        : 'session_${DateTime.now().millisecondsSinceEpoch}';

    final currentMessages = state is ChatbotLoaded
        ? List<ChatMessage>.from((state as ChatbotLoaded).messages)
        : <ChatMessage>[];

    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: sanitized,
      imagePath: event.imagePath,
      timestamp: DateTime.now(),
    );

    currentMessages.add(userMessage);

    emit(ChatbotLoaded(
      sessionId: sessionId,
      messages: List.from(currentMessages),
      isStreaming: true,
      sessions: sessions,
    ));

    final botTimestamp = DateTime.now();
    final botMessage = ChatMessage(
      id: 'msg_${botTimestamp.millisecondsSinceEpoch}',
      role: MessageRole.bot,
      content: '',
      timestamp: botTimestamp,
      isStreaming: true,
    );

    currentMessages.add(botMessage);
    final botIndex = currentMessages.length - 1;

    emit(ChatbotLoaded(
      sessionId: sessionId,
      messages: List.from(currentMessages),
      isStreaming: true,
      sessions: sessions,
    ));

    String accumulatedText = '';

    try {
      final stream = _chatbotRepository.sendMessage(
        userText: sanitized,
        imagePath: event.imagePath,
        currentWeather: event.currentWeather,
        plantingSchedules: event.plantingSchedules,
        recentScanHistory: event.recentScanHistory,
      );

      await for (final token in stream) {
        if (isClosed) return;
        accumulatedText += token;
        currentMessages[botIndex] = ChatMessage(
          id: botMessage.id,
          role: MessageRole.bot,
          content: accumulatedText,
          timestamp: botTimestamp,
          isStreaming: true,
        );
        emit(ChatbotLoaded(
          sessionId: sessionId,
          messages: List.from(currentMessages),
          isStreaming: true,
          sessions: sessions,
        ));
      }

      if (isClosed) return;
      currentMessages[botIndex] = ChatMessage(
        id: botMessage.id,
        role: MessageRole.bot,
        content: accumulatedText,
        timestamp: botTimestamp,
        isStreaming: false,
      );

      // Simpan percakapan ke Hive
      final existingSession = _chatbotRepository.getChatSession(sessionId);
      final sessionTitle = existingSession?.title ??
          _generateSessionTitle(sanitized, event.imagePath);

      final updatedSession = ChatSession(
        id: sessionId,
        title: sessionTitle,
        createdAt: existingSession?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        messages: List.from(currentMessages),
      );

      await _chatbotRepository.saveChatSession(updatedSession);
      await _chatbotRepository.setLastActiveSessionId(sessionId);

      final updatedSessions = _chatbotRepository.getChatSessions();

      emit(ChatbotLoaded(
        sessionId: sessionId,
        messages: List.from(currentMessages),
        isStreaming: false,
        sessions: updatedSessions,
      ));
    } catch (e) {
      if (isClosed) return;
      debugPrint('ChatbotBloc Error: $e');
      currentMessages[botIndex] = ChatMessage(
        id: botMessage.id,
        role: MessageRole.bot,
        content: accumulatedText.isNotEmpty
            ? accumulatedText
            : 'Maaf, terjadi kesalahan saat menghubungi asisten AI. Silakan periksa koneksi atau coba lagi.',
        timestamp: botTimestamp,
        isStreaming: false,
      );

      // Simpan session yang sudah ada meskipun ada error parsial
      try {
        final existingSession = _chatbotRepository.getChatSession(sessionId);
        final sessionTitle = existingSession?.title ??
            _generateSessionTitle(sanitized, event.imagePath);
        final updatedSession = ChatSession(
          id: sessionId,
          title: sessionTitle,
          createdAt: existingSession?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          messages: List.from(currentMessages),
        );
        await _chatbotRepository.saveChatSession(updatedSession);
      } catch (_) {}

      final updatedSessions = _chatbotRepository.getChatSessions();

      emit(ChatbotError(
        sessionId: sessionId,
        messages: List.from(currentMessages),
        error: e.toString(),
        sessions: updatedSessions,
      ));
    }
  }

  void _onLoadChatSession(LoadChatSession event, Emitter<ChatbotState> emit) {
    final sessions = _chatbotRepository.getChatSessions();
    final session = _chatbotRepository.getChatSession(event.sessionId);

    if (session != null) {
      _chatbotRepository.loadSessionHistory(session.messages);
      _chatbotRepository.setLastActiveSessionId(session.id);
      emit(ChatbotLoaded(
        sessionId: session.id,
        messages: List.from(session.messages),
        isStreaming: false,
        sessions: sessions,
      ));
    }
  }

  void _onStartNewChat(StartNewChat event, Emitter<ChatbotState> emit) {
    _chatbotRepository.resetSession();
    _chatbotRepository.setLastActiveSessionId(null);
    final sessions = _chatbotRepository.getChatSessions();
    emit(ChatbotInitial(sessions: sessions));
  }

  Future<void> _onDeleteChatSession(
    DeleteChatSession event,
    Emitter<ChatbotState> emit,
  ) async {
    await _chatbotRepository.deleteChatSession(event.sessionId);
    final sessions = _chatbotRepository.getChatSessions();

    final currentSessionId = state is ChatbotLoaded
        ? (state as ChatbotLoaded).sessionId
        : state is ChatbotError
            ? (state as ChatbotError).sessionId
            : null;

    if (currentSessionId == event.sessionId) {
      _chatbotRepository.resetSession();
      await _chatbotRepository.setLastActiveSessionId(null);
      emit(ChatbotInitial(sessions: sessions));
    } else {
      if (state is ChatbotLoaded) {
        final current = state as ChatbotLoaded;
        emit(current.copyWith(sessions: sessions));
      } else if (state is ChatbotInitial) {
        emit(ChatbotInitial(sessions: sessions));
      }
    }
  }

  Future<void> _onClearAllChatHistory(
    ClearAllChatHistory event,
    Emitter<ChatbotState> emit,
  ) async {
    await _chatbotRepository.clearAllChatSessions();
    _chatbotRepository.resetSession();
    await _chatbotRepository.setLastActiveSessionId(null);
    emit(const ChatbotInitial(sessions: []));
  }

  void _onResetChat(ResetChat event, Emitter<ChatbotState> emit) {
    add(const StartNewChat());
  }
}
