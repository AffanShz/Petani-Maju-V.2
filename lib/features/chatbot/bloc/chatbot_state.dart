part of 'chatbot_bloc.dart';

abstract class ChatbotState extends Equatable {
  const ChatbotState();

  @override
  List<Object?> get props => [];
}

class ChatbotInitial extends ChatbotState {
  const ChatbotInitial();
}

class ChatbotLoaded extends ChatbotState {
  final List<ChatMessage> messages;
  final bool isStreaming;

  const ChatbotLoaded({
    required this.messages,
    this.isStreaming = false,
  });

  @override
  List<Object?> get props => [messages, isStreaming];

  ChatbotLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
  }) {
    return ChatbotLoaded(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ChatbotError extends ChatbotState {
  final List<ChatMessage> messages;
  final String error;

  const ChatbotError({
    required this.messages,
    required this.error,
  });

  @override
  List<Object?> get props => [messages, error];
}
