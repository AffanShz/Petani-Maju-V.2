part of 'chatbot_bloc.dart';

abstract class ChatbotState extends Equatable {
  final List<ChatSession> sessions;
  const ChatbotState({this.sessions = const []});

  @override
  List<Object?> get props => [sessions];
}

class ChatbotInitial extends ChatbotState {
  const ChatbotInitial({super.sessions});
}

class ChatbotLoaded extends ChatbotState {
  final String sessionId;
  final List<ChatMessage> messages;
  final bool isStreaming;

  const ChatbotLoaded({
    required this.sessionId,
    required this.messages,
    this.isStreaming = false,
    super.sessions,
  });

  @override
  List<Object?> get props => [sessionId, messages, isStreaming, sessions];

  ChatbotLoaded copyWith({
    String? sessionId,
    List<ChatMessage>? messages,
    bool? isStreaming,
    List<ChatSession>? sessions,
  }) {
    return ChatbotLoaded(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      sessions: sessions ?? this.sessions,
    );
  }
}

class ChatbotError extends ChatbotState {
  final String? sessionId;
  final List<ChatMessage> messages;
  final String error;

  const ChatbotError({
    this.sessionId,
    required this.messages,
    required this.error,
    super.sessions,
  });

  @override
  List<Object?> get props => [sessionId, messages, error, sessions];
}

/// Pesan ditolak karena kuota chat gratis hari ini habis.
///
/// Dipancarkan dari [ChatbotBloc] apapun jalur masuknya, sehingga UI cukup
/// menampilkan dialog upgrade tanpa perlu ikut menghitung kuota sendiri.
class ChatbotQuotaExceeded extends ChatbotState {
  final String? sessionId;
  final List<ChatMessage> messages;

  const ChatbotQuotaExceeded({
    this.sessionId,
    required this.messages,
    super.sessions,
  });

  @override
  List<Object?> get props => [sessionId, messages, sessions];
}
