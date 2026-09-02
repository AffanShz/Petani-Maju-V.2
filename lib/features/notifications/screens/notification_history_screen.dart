import 'package:flutter/material.dart';
import 'package:petani_maju/core/services/cache_service.dart';
import 'package:petani_maju/core/constants/colors.dart';
import 'package:intl/intl.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = _sortForDisplay(CacheService().getNotificationHistory());
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Histori'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus semua histori notifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CacheService().clearNotificationHistory();
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Histori notifikasi dihapus'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Label waktu relatif, naik bertingkat: menit -> jam -> hari -> tanggal.
  ///
  /// Riwayat ini memuat dua macam entri. Notifikasi yang sudah tayang disimpan
  /// dengan waktu saat itu (masa lalu), sedangkan pengingat yang dijadwalkan
  /// disimpan dengan waktu jadwalnya (masa depan). Versi sebelumnya selalu
  /// memakai kalimat "yang lalu" dan membandingkan selisih negatif dengan
  /// batas 60, sehingga jadwal 15 hari ke depan tampil sebagai
  /// "-21036 menit yang lalu". Arah waktunya sekarang dibedakan.
  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.tryParse(timestamp);
    if (dateTime == null) return '';

    final now = DateTime.now();

    if (dateTime.isAfter(now)) {
      final d = dateTime.difference(now);
      if (d.inMinutes < 1) return 'Sebentar lagi';
      if (d.inMinutes < 60) return '${d.inMinutes} menit lagi';
      if (d.inHours < 24) return '${d.inHours} jam lagi';
      if (d.inDays < 7) return '${d.inDays} hari lagi';
      return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
    }

    final d = now.difference(dateTime);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays == 1) return 'Kemarin';
    if (d.inDays < 7) return '${d.inDays} hari lalu';
    return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
  }

  bool _isUpcoming(Map<String, dynamic> n) {
    final t = DateTime.tryParse(n['timestamp'] ?? '');
    return t != null && t.isAfter(DateTime.now());
  }

  /// Urutkan supaya terbaca wajar: pengingat yang paling dekat lebih dulu,
  /// lalu riwayat yang sudah tayang dari yang terbaru.
  ///
  /// Tanpa ini daftarnya memakai urutan waktu menurun, yang menaruh jadwal
  /// paling jauh di masa depan justru di paling atas.
  List<Map<String, dynamic>> _sortForDisplay(List<Map<String, dynamic>> items) {
    final upcoming = items.where(_isUpcoming).toList()
      ..sort((a, b) => DateTime.parse(a['timestamp'])
          .compareTo(DateTime.parse(b['timestamp'])));
    final past = items.where((n) => !_isUpcoming(n)).toList()
      ..sort((a, b) {
        final tA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
        final tB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
        return tB.compareTo(tA);
      });
    return [...upcoming, ...past];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Semua',
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _loadNotifications();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10), // Updated to use withAlpha
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(30), // Updated
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] ?? 'Notifikasi',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _isUpcoming(notification)
                                ? Icons.schedule_rounded
                                : Icons.history_rounded,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatTime(notification['timestamp']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['body'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )));
  }
}
