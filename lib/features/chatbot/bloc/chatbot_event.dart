part of 'chatbot_bloc.dart';

abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();

  @override
  List<Object?> get props => [];
}

class InitChatbot extends ChatbotEvent {
  final String? sessionId;
  const InitChatbot({this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class SendMessage extends ChatbotEvent {
  final String text;
  final String? imagePath;
  final Map<String, dynamic>? currentWeather;
  final List<dynamic>? plantingSchedules;
  final List<dynamic>? recentScanHistory;

  const SendMessage({
    required this.text,
    this.imagePath,
    this.currentWeather,
    this.plantingSchedules,
    this.recentScanHistory,
  });

  @override
  List<Object?> get props => [
        text,
        imagePath,
        currentWeather,
        plantingSchedules,
        recentScanHistory,
      ];
}

class LoadChatSession extends ChatbotEvent {
  final String sessionId;
  const LoadChatSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class StartNewChat extends ChatbotEvent {
  const StartNewChat();
}

class DeleteChatSession extends ChatbotEvent {
  final String sessionId;
  const DeleteChatSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class ClearAllChatHistory extends ChatbotEvent {
  const ClearAllChatHistory();
}

class ResetChat extends ChatbotEvent {
  const ResetChat();
}
