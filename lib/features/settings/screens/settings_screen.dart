import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:petani_maju/core/constants/colors.dart';
import 'package:petani_maju/core/services/cache_service.dart';
import 'package:petani_maju/features/settings/screens/profile_screen.dart';

import 'package:petani_maju/features/settings/screens/notification_settings_screen.dart';
import 'package:petani_maju/features/settings/screens/help_support_screen.dart';
import 'package:petani_maju/features/settings/screens/about_app_screen.dart';
import 'package:petani_maju/core/services/connectivity_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _offlineSubscription;
  StreamSubscription<Map<String, String?>>? _profileSubscription;
  bool _offlineMode = false;
  String _userName = 'Pak Tani';
  String? _userImagePath;

  @override
  void initState() {
    super.initState();
    _loadOfflineMode();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _offlineSubscription =
        _connectivityService.offlineStatusStream.listen((isOffline) {
      if (mounted) {
        setState(() {
          _offlineMode = isOffline;
        });
      }
    });

    _profileSubscription = _cacheService.profileUpdateStream.listen((profile) {
      if (mounted) {
        setState(() {
          _userName = profile['name'] ?? 'Pak Tani';
          _userImagePath = profile['imagePath'];
        });
      }
    });
  }

  @override
  void dispose() {
    _offlineSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _loadOfflineMode() {
    setState(() {
      _offlineMode = _cacheService.getOfflineMode();
      final profile = _cacheService.getUserProfile();
      _userName = profile['name'] ?? 'Pak Tani';
      _userImagePath = profile['imagePath'];
    });
  }

  Future<void> _toggleOfflineMode(bool value) async {
    await _cacheService.setOfflineMode(value);
    setState(() {
      _offlineMode = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'settings.offline_active'.tr()
              : 'settings.online_active'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'settings.title'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              _buildProfileSection(),
              const SizedBox(height: 24),

              // AKUN Section
              _buildSectionTitle('settings.account_section'.tr()),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'settings.profile'.tr(),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                    if (result == true) {
                      _loadOfflineMode();
                    }
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // PREFERENSI Section
              _buildSectionTitle('settings.preferences_section'.tr()),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'settings.notification_menu'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.language_outlined,
                  title: 'settings.language'.tr(),
                  subtitle: context.locale.languageCode == 'id'
                      ? 'Indonesia'
                      : 'English',
                  onTap: () {
                    _showLanguageModal(context);
                  },
                ),
                _buildDivider(),
                _buildSettingsTileWithSwitch(
                  icon: Icons.cloud_off_outlined,
                  title: 'settings.offline_mode'.tr(),
                  value: _offlineMode,
                  onChanged: _toggleOfflineMode,
                ),
              ]),
              const SizedBox(height: 24),

              // TENTANG Section
              _buildSectionTitle('settings.about_section'.tr()),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: null,
                  title: 'settings.help'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: null,
                  title: 'settings.about'.tr(),
                  subtitle: 'v1.0.0',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutAppScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    ImageProvider? imageProvider;
    if (_userImagePath != null && _userImagePath!.isNotEmpty) {
      imageProvider = FileImage(File(_userImagePath!));
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primaryGreen,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, color: Colors.white, size: 32)
              : null,
          onBackgroundImageError: imageProvider != null
              ? (exception, stackTrace) {
                  if (kDebugMode) print("Settings Profile Image Error: $exception");
                }
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Petani Maju',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    IconData? icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Colors.grey[700],
                size: 24,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTileWithSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[700],
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'settings.language'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
                title: const Text('Indonesia'),
                trailing: context.locale.languageCode == 'id'
                    ? const Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  context.setLocale(const Locale('id'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English'),
                trailing: context.locale.languageCode == 'en'
                    ? const Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  context.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
