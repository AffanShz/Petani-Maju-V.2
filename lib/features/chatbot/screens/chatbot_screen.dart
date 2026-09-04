import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agrinova/core/constants/colors.dart';
import 'package:agrinova/data/models/chat_message.dart';
import 'package:agrinova/data/repositories/calendar_repository.dart';

import 'package:agrinova/data/repositories/chatbot_repository.dart';
import 'package:agrinova/data/repositories/history_repository.dart';
import 'package:agrinova/features/chatbot/bloc/chatbot_bloc.dart';
import 'package:agrinova/features/chatbot/screens/chat_history_screen.dart';
import 'package:agrinova/features/premium/widgets/upgrade_to_pro_dialog.dart';

import 'package:agrinova/features/chatbot/widgets/chat_bubble.dart';
import 'package:agrinova/features/chatbot/widgets/chat_input_bar.dart';
import 'package:agrinova/widgets/app_toast.dart';

class ChatbotScreen extends StatelessWidget {
  final Map<String, dynamic>? currentWeather;
  final String? initialPrompt;
  final String? initialImagePath;
  final bool autoSend;

  const ChatbotScreen({
    super.key,
    this.currentWeather,
    this.initialPrompt,
    this.initialImagePath,
    this.autoSend = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatbotBloc(
        chatbotRepository: context.read<ChatbotRepository>(),
      ),
      child: _ChatbotView(
        currentWeather: currentWeather,
        initialPrompt: initialPrompt,
        initialImagePath: initialImagePath,
        autoSend: autoSend,
      ),
    );
  }
}

class _ChatbotView extends StatefulWidget {
  final Map<String, dynamic>? currentWeather;
  final String? initialPrompt;
  final String? initialImagePath;
  final bool autoSend;

  const _ChatbotView({
    this.currentWeather,
    this.initialPrompt,
    this.initialImagePath,
    this.autoSend = false,
  });

  @override
  State<_ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<_ChatbotView> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic>? _plantingSchedules;
  List<dynamic>? _recentScanHistory;

  @override
  void initState() {
    super.initState();
    _loadExtraContext();

    if (widget.autoSend &&
        (widget.initialPrompt != null || widget.initialImagePath != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatbotBloc>().add(const StartNewChat());
        _dispatchSendMessage(
          text: widget.initialPrompt ?? '',
          imagePath: widget.initialImagePath,
        );
      });
    }
  }

  Future<void> _loadExtraContext() async {
    final calendarRepo = context.read<CalendarRepository>();
    final historyRepo = context.read<HistoryRepository>();

    try {
      final schedules = await calendarRepo.fetchSchedules();
      if (mounted) {
        setState(() {
          _plantingSchedules = schedules;
        });
      }
    } catch (_) {}

    try {
      final history = await historyRepo.getHistory();
      if (mounted) {
        setState(() {
          _recentScanHistory = history.map((e) => e.toMap()).toList();
        });
      }
    } catch (_) {}
  }

  void _dispatchSendMessage({required String text, String? imagePath}) {
    context.read<ChatbotBloc>().add(SendMessage(
          text: text,
          imagePath: imagePath,
          currentWeather: widget.currentWeather,
          plantingSchedules: _plantingSchedules,
          recentScanHistory: _recentScanHistory,
        ));
  }


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
    if (lower.contains('503') ||
        lower.contains('high demand') ||
        lower.contains('unavailable') ||
        lower.contains('overloaded')) {
      return 'Server Gemini AI sedang mengalami lonjakan trafik (503). Sistem telah mencoba model cadangan, silakan coba kirim ulang pesan.';
    }

    if (lower.contains('quota') ||
        lower.contains('rate limit') ||
        lower.contains('429')) {
      return 'Terlalu banyak permintaan, coba lagi nanti.';
    }
    return raw;
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

  void _openHistory(BuildContext context) {
    final bloc = context.read<ChatbotBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const ChatHistoryScreen(),
        ),
      ),
    );
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
            Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 22),
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
          IconButton(
            onPressed: () => _openHistory(context),
            tooltip: 'Riwayat Konsultasi',
            icon: const Icon(
              Icons.history_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
          IconButton(
            onPressed: () => context.read<ChatbotBloc>().add(const StartNewChat()),
            tooltip: 'Chat Baru',
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppColors.primaryGreen,
            ),
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
                  AppToast.show(
                    context,
                    message: errorMsg,
                    type: ToastType.error,
                  );
                }
                if (state is ChatbotQuotaExceeded) {
                  showUpgradeToProDialog(context);
                }
              },
              builder: (context, state) {
                if (state is ChatbotInitial) {
                  return _buildWelcomeScreen();
                }

                final messages = state is ChatbotLoaded
                    ? state.messages
                    : state is ChatbotError
                        ? state.messages
                        : state is ChatbotQuotaExceeded
                            ? state.messages
                            : const <ChatMessage>[];


                if (messages.isEmpty) {
                  return _buildWelcomeScreen();
                }

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
                onSend: (text, imagePath) {
                  _dispatchSendMessage(text: text, imagePath: imagePath);

                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 48,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Asisten Tani & Kebun',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tanyakan seputar pertanian & perkebunan: kondisi kebun, analisis foto, pupuk, jadwal panen, atau konsultasi penyakit tanaman.',

                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSuggestionChip('🌱 Bagaimanakah ringkasan kondisi kebun dan cuaca saat ini?'),
                    const SizedBox(height: 8),
                    _buildSuggestionChip('🐛 Cara mengatasi hama wereng cokelat pada tanaman padi?'),
                    const SizedBox(height: 8),
                    _buildSuggestionChip('💊 Rekomendasi obat fungisida untuk daun cabai keriting menguning?'),
                    const SizedBox(height: 8),
                    _buildSuggestionChip('📅 Kapan jadwal ideal pemupukan & perkiraan panen komoditas saya?'),

                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Builder(builder: (context) {
      return GestureDetector(
        onTap: () {
          _dispatchSendMessage(text: text);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
