part of 'chatbot_bloc.dart';

abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();

  @override
  List<Object?> get props => [];
}

class SendMessage extends ChatbotEvent {
  final String text;
  final Map<String, dynamic>? currentWeather;

  const SendMessage({
    required this.text,
    this.currentWeather,
  });

  @override
  List<Object?> get props => [text, currentWeather];
}

class ResetChat extends ChatbotEvent {
  const ResetChat();
}
