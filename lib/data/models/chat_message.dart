enum MessageRole { user, bot }

class ChatMessage {
  final String? id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String? imagePath;
  final bool isStreaming;

  const ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.imagePath,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    String? imagePath,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.bot,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      imagePath: json['imagePath'] as String?,
      isStreaming: false,
    );
  }
}
