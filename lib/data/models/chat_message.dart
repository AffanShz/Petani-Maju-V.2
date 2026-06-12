enum MessageRole { user, bot }

class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
