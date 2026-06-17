import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:petani_maju/data/repositories/chatbot_repository.dart';
import 'package:petani_maju/features/chatbot/bloc/chatbot_bloc.dart';
import 'package:petani_maju/features/chatbot/widgets/chat_bubble.dart';
import 'package:petani_maju/features/chatbot/widgets/chat_input_bar.dart';

class ChatbotScreen extends StatelessWidget {
  final Map<String, dynamic>? currentWeather;

  const ChatbotScreen({super.key, this.currentWeather});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatbotBloc(
        chatbotRepository: context.read<ChatbotRepository>(),
      ),
      child: _ChatbotView(currentWeather: currentWeather),
    );
  }
}

class _ChatbotView extends StatefulWidget {
  final Map<String, dynamic>? currentWeather;

  const _ChatbotView({this.currentWeather});

  @override
  State<_ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<_ChatbotView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('api key') ||
        lower.contains('apikey') ||
        lower.contains('invalid') ||
        lower.contains('403') ||
        lower.contains('401') ||
        lower.contains('permission')) {
      return 'API key tidak valid. Periksa GEMINI_API_KEY di .env.';
    }
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('host') ||
        lower.contains('connect')) {
      return 'Tidak ada koneksi internet.';
    }
    if (lower.contains('quota') || lower.contains('rate limit') || lower.contains('429')) {
      return 'Terlalu banyak permintaan, coba lagi nanti.';
    }
    return 'Error: $raw';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text(
              'Asisten Tani',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<ChatbotBloc, ChatbotState>(
            builder: (context, state) {
              final hasMessages =
                  state is ChatbotLoaded && state.messages.isNotEmpty;
              return _AnimatedRefreshButton(
                enabled: hasMessages,
                onTap: () => context.read<ChatbotBloc>().add(const ResetChat()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatbotBloc, ChatbotState>(
              listener: (context, state) {
                _scrollToBottom();
                if (state is ChatbotError) {
                  final errorMsg = _friendlyError(state.error);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatbotInitial) {
                  return _buildWelcomeScreen();
                }

                final messages = state is ChatbotLoaded
                    ? state.messages
                    : (state as ChatbotError).messages;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),
          BlocBuilder<ChatbotBloc, ChatbotState>(
            builder: (context, state) {
              final isStreaming =
                  state is ChatbotLoaded && state.isStreaming;
              return ChatInputBar(
                isStreaming: isStreaming,
                onSend: (text) {
                  context.read<ChatbotBloc>().add(SendMessage(
                        text: text,
                        currentWeather: widget.currentWeather,
                      ));
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, size: 48, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Asisten Tani',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tanyakan apa saja seputar pertanian, tanaman, hama, pupuk, atau jadwal tanam.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildSuggestionChip('Cara mengatasi hama wereng?'),
            const SizedBox(height: 8),
            _buildSuggestionChip('Kapan waktu terbaik tanam padi?'),
            const SizedBox(height: 8),
            _buildSuggestionChip('Pupuk apa untuk tanaman cabai?'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Builder(builder: (context) {
      return GestureDetector(
        onTap: () {
          context.read<ChatbotBloc>().add(SendMessage(
                text: text,
                currentWeather: widget.currentWeather,
              ));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 13,
            ),
          ),
        ),
      );
    });
  }
}

class _AnimatedRefreshButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AnimatedRefreshButton({required this.enabled, required this.onTap});

  @override
  State<_AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<_AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.enabled ? _handleTap : null,
      tooltip: 'Reset chat',
      icon: RotationTransition(
        turns: _controller,
        child: Icon(
          Icons.refresh_outlined,
          color: widget.enabled ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
