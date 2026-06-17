import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../../../data/models/prediction_history.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        title: const Text(
          'Riwayat Deteksi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoaded && state.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                  tooltip: 'Hapus Semua',
                  onPressed: () => _confirmDeleteAll(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 12),
                  Text('Memuat riwayat...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (state is HistoryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 72, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<HistoryBloc>().add(LoadHistory()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is HistoryLoaded) {
            if (state.items.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildHistoryList(context, state.items);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_outlined, size: 60, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada riwayat scan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Foto daun tanaman kamu untuk\nmulai mendeteksi penyakit',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<PredictionHistory> items) {
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async {
        context.read<HistoryBloc>().add(LoadHistory());
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _HistoryCard(
            item: items[index],
            onDelete: () => _confirmDelete(context, items[index]),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, PredictionHistory item) {
    final bloc = context.read<HistoryBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Riwayat?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Hasil deteksi "${item.disease}" pada ${DateFormat('d MMM yyyy', 'id_ID').format(item.createdAt)} akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(DeleteHistoryItem(item.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    final bloc = context.read<HistoryBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semua Riwayat?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Semua riwayat deteksi akan dihapus secara permanen dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(DeleteAllHistory());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final PredictionHistory item;
  final VoidCallback onDelete;

  const _HistoryCard({required this.item, required this.onDelete});

  Color _getStatusColor() {
    final disease = item.disease.toLowerCase();
    if (disease.contains('sehat') || disease.contains('healthy')) {
      return const Color(0xFF2E7D32);
    } else if (item.confidence > 0.85) {
      return const Color(0xFFB71C1C);
    } else {
      return const Color(0xFFF57F17);
    }
  }

  Color _getStatusBgColor() {
    final color = _getStatusColor();
    return color.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final dateStr = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(item.createdAt);
    final confidenceStr = '${(item.confidence * 100).toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            onDelete();
            return false; // We handle deletion via dialog
          },
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 28),
                SizedBox(height: 4),
                Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              SizedBox(
                width: 100,
                height: 110,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFE8F5E9),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFE8F5E9),
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
                  ),
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Disease label + confidence badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.disease,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          GestureDetector(
                            onTap: onDelete,
                            child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Confidence chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Kepercayaan: $confidenceStr',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Plant type
                      Row(
                        children: [
                          const Icon(Icons.eco_outlined, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            item.plantType,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Date
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
