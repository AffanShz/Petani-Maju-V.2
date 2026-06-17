import 'package:flutter/material.dart';
import 'package:petani_maju/data/models/chat_message.dart';
import 'package:petani_maju/features/chatbot/widgets/streaming_text.dart';

String _cleanMarkdown(String text) {
  return text
      .replaceAll('**', '')
      .replaceAll(RegExp(r'^\* ', multiLine: true), '• ')
      .replaceAll('*', '')
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.eco, size: 18, color: Colors.green),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.green : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.content.isEmpty && message.isStreaming
                  ? _buildTypingIndicator()
                  : StreamingText(
                      content: isUser ? message.content : _cleanMarkdown(message.content),
                      isStreaming: message.isStreaming,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => _Dot(delay: i * 200)),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
