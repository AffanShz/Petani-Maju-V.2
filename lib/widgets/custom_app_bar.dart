import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/core/constants/colors.dart';
import 'package:petani_maju/core/services/cache_service.dart';
import 'package:petani_maju/features/notifications/screens/notification_history_screen.dart';

class CustomAppBar extends StatefulWidget {
  final DateTime? lastSyncTime;
  final bool isOnline;

  const CustomAppBar({
    super.key,
    this.lastSyncTime,
    this.isOnline = true,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final CacheService _cacheService = CacheService();
  StreamSubscription<Map<String, String?>>? _profileSubscription;
  String _userName = 'Pak Tani';
  String? _userImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _profileSubscription = _cacheService.profileUpdateStream.listen((profile) {
      if (mounted) {
        setState(() {
          _userName = profile['name'] ?? 'profile.default_name'.tr();
          _userImagePath = profile['imagePath'];
        });
      }
    });
  }

  void _loadProfile() {
    final profile = _cacheService.getUserProfile();
    setState(() {
      _userName = profile['name'] ?? 'profile.default_name'.tr();
      _userImagePath = profile['imagePath'];
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  String _formatLastSync() {
    if (widget.lastSyncTime == null) return 'home.sync_not_synced'.tr();

    final now = DateTime.now();
    final diff = now.difference(widget.lastSyncTime!);

    if (diff.inMinutes < 1) {
      return 'home.sync_just_now'.tr();
    } else if (diff.inMinutes < 60) {
      return 'home.sync_min_ago'.tr(args: [diff.inMinutes.toString()]);
    } else if (diff.inHours < 24) {
      return 'home.sync_hour_ago'.tr(args: [diff.inHours.toString()]);
    } else {
      return 'home.sync_day_ago'.tr(args: [diff.inDays.toString()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_userImagePath != null && _userImagePath!.isNotEmpty) {
      imageProvider = FileImage(File(_userImagePath!));
    }

    return Column(
      children: [
        // Profile Row
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryGreen,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person, color: Colors.white, size: 28)
                        : null,
                    onBackgroundImageError: imageProvider != null
                        ? (exception, stackTrace) {
                            if (kDebugMode) print("AppBar Profile Image Error: $exception");
                          }
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'app_name'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_outlined, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Sync Status Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isOnline
                ? AppColors.primaryGreen
                : AppColors.primaryGreen.withAlpha(200),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isOnline
                    ? 'home.sync_online'.tr(args: [_formatLastSync()])
                    : 'home.sync_offline'.tr(args: [_formatLastSync()]),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
