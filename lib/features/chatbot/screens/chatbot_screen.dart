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
              return IconButton(
                onPressed: hasMessages
                    ? () => context.read<ChatbotBloc>().add(const ResetChat())
                    : null,
                icon: const Icon(Icons.refresh_outlined),
                tooltip: 'Reset chat',
                color: hasMessages ? Colors.green : Colors.grey,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Gagal mendapat respons. Periksa koneksi internet.'),
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
