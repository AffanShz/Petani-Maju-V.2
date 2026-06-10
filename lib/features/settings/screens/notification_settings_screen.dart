// lib/features/settings/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/core/constants/colors.dart';
import 'package:petani_maju/core/services/cache_service.dart';
import 'package:petani_maju/core/services/notification_scheduler.dart';
import 'package:petani_maju/data/models/notification_settings.dart';
import 'package:petani_maju/widgets/custom_time_picker.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final CacheService _cacheService = CacheService();
  final NotificationScheduler _scheduler = NotificationScheduler();
  late NotificationSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _settings = _cacheService.getNotificationSettings();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _scheduler.saveSettings(_settings);

    // Reschedule morning briefing if enabled
    if (_settings.morningBriefingEnabled) {
      await _scheduler.scheduleMorningBriefing();
    } else {
      await _scheduler.cancelMorningBriefing();
    }
  }

  void _updateSettings(NotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'notifications.title'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Morning Briefing Section
              _buildSectionTitle('notifications.section_daily_weather'.tr()),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'notifications.morning_weather'.tr(),
                  subtitle: 'notifications.morning_weather_desc'.tr(),
                  value: _settings.morningBriefingEnabled,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(morningBriefingEnabled: value));
                  },
                ),
                if (_settings.morningBriefingEnabled) ...[
                  _buildDivider(),
                  _buildTimePicker(
                    title: 'notifications.notification_time'.tr(),
                    hour: _settings.morningBriefingHour,
                    minute: _settings.morningBriefingMinute,
                    onChanged: (hour, minute) {
                      _updateSettings(_settings.copyWith(
                        morningBriefingHour: hour,
                        morningBriefingMinute: minute,
                      ));
                    },
                  ),
                ],
              ]),
              const SizedBox(height: 24),

              // Weather Alerts Section
              _buildSectionTitle('notifications.section_weather_alerts'.tr()),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.water_drop_outlined,
                  title: 'notifications.heavy_rain'.tr(),
                  subtitle: 'notifications.heavy_rain_desc'.tr(),
                  value: _settings.heavyRainAlertEnabled,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(heavyRainAlertEnabled: value));
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.air_outlined,
                  title: 'notifications.strong_wind'.tr(),
                  subtitle: 'notifications.strong_wind_desc'.tr(),
                  value: _settings.strongWindAlertEnabled,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(strongWindAlertEnabled: value));
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.flash_on_outlined,
                  title: 'notifications.thunderstorm'.tr(),
                  subtitle: 'notifications.thunderstorm_desc'.tr(),
                  value: _settings.thunderstormAlertEnabled,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(thunderstormAlertEnabled: value));
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Farming Reminders Section
              _buildSectionTitle(
                  'notifications.section_farming_reminders'.tr()),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.science_outlined,
                  title: 'notifications.fertilization'.tr(),
                  subtitle: 'notifications.fertilization_desc'.tr(),
                  value: _settings.fertilizationReminderEnabled,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(
                        fertilizationReminderEnabled: value));
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.opacity_outlined,
                  title: 'notifications.smart_watering'.tr(),
                  subtitle: 'notifications.smart_watering_desc'.tr(),
                  value: _settings.smartWateringEnabled,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(smartWateringEnabled: value));
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.bug_report_outlined,
                  title: 'notifications.pest_warning'.tr(),
                  subtitle: 'notifications.pest_warning_desc'.tr(),
                  value: _settings.pestWarningEnabled,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(pestWarningEnabled: value));
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Calendar Reminders Section
              _buildSectionTitle(
                  'notifications.section_calendar_reminders'.tr()),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.event_outlined,
                  title: 'notifications.calendar_1day'.tr(),
                  subtitle: 'notifications.calendar_1day_desc'.tr(),
                  value: _settings.reminder1DayBefore,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(reminder1DayBefore: value));
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.schedule_outlined,
                  title: 'notifications.calendar_1hour'.tr(),
                  subtitle: 'notifications.calendar_1hour_desc'.tr(),
                  value: _settings.reminder1HourBefore,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(reminder1HourBefore: value));
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'notifications.calendar_ontime'.tr(),
                  subtitle: 'notifications.calendar_ontime_desc'.tr(),
                  value: _settings.reminderAtTime,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(reminderAtTime: value));
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Quiet Mode Section
              _buildSectionTitle('notifications.section_quiet_mode'.tr()),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'notifications.quiet_mode'.tr(),
                  subtitle: 'notifications.quiet_mode_desc'.tr(),
                  value: _settings.quietModeEnabled,
                  onChanged: (value) {
                    _updateSettings(
                        _settings.copyWith(quietModeEnabled: value));
                  },
                ),
                if (_settings.quietModeEnabled) ...[
                  _buildDivider(),
                  _buildQuietHoursPicker(),
                ],
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primaryGreen.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? AppColors.primaryGreen : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String title,
    required int hour,
    required int minute,
    required Function(int, int) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.access_time,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () async {
              TimeOfDay tempTime = TimeOfDay(hour: hour, minute: minute);
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('common.select_time'.tr()),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: CustomTimePicker(
                          initialTime: tempTime,
                          onTimeChanged: (newTime) {
                            tempTime = newTime;
                          },
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('common.cancel'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onChanged(tempTime.hour, tempTime.minute);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('common.save'.tr()),
                    ),
                  ],
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bedtime_outlined,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'notifications.quiet_hours'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHourSelector(
                label: 'notifications.from'.tr(),
                hour: _settings.quietStartHour,
                onTap: () async {
                  TimeOfDay tempTime =
                      TimeOfDay(hour: _settings.quietStartHour, minute: 0);
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('notifications.start_quiet_hours'.tr()),
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: CustomTimePicker(
                              initialTime: tempTime,
                              onTimeChanged: (newTime) {
                                tempTime = newTime;
                              },
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('common.cancel'.tr()),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _updateSettings(_settings.copyWith(
                                quietStartHour: tempTime.hour));
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('common.save'.tr()),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              _buildHourSelector(
                label: 'notifications.to'.tr(),
                hour: _settings.quietEndHour,
                onTap: () async {
                  TimeOfDay tempTime =
                      TimeOfDay(hour: _settings.quietEndHour, minute: 0);
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('notifications.end_quiet_hours'.tr()),
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: CustomTimePicker(
                              initialTime: tempTime,
                              onTimeChanged: (newTime) {
                                tempTime = newTime;
                              },
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('common.cancel'.tr()),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _updateSettings(_settings.copyWith(
                                quietEndHour: tempTime.hour));
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('common.save'.tr()),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourSelector({
    required String label,
    required int hour,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }
}
