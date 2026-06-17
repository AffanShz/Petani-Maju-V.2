import 'package:flutter/material.dart';

class StreamingText extends StatefulWidget {
  final String content;
  final bool isStreaming;
  final TextStyle? style;

  const StreamingText({
    super.key,
    required this.content,
    required this.isStreaming,
    this.style,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _cursorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_cursorController);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isStreaming) {
      return Text(widget.content, style: widget.style);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(widget.content, style: widget.style),
        ),
        FadeTransition(
          opacity: _cursorOpacity,
          child: Text(
            '▍',
            style: (widget.style ?? const TextStyle()).copyWith(
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}
