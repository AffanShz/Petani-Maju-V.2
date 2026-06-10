// lib/data/models/notification_settings.dart

/// Model untuk menyimpan preferensi notifikasi pengguna
class NotificationSettings {
  // Morning Briefing
  final bool morningBriefingEnabled;
  final int morningBriefingHour;
  final int morningBriefingMinute;

  // Weather Alerts
  final bool heavyRainAlertEnabled;
  final bool strongWindAlertEnabled;
  final bool thunderstormAlertEnabled;

  // Farming Reminders
  final bool fertilizationReminderEnabled;
  final bool smartWateringEnabled;
  final bool pestWarningEnabled;

  // Calendar Reminders
  final bool reminder1DayBefore;
  final bool reminder1HourBefore;
  final bool reminderAtTime;

  // Quiet Hours
  final bool quietModeEnabled;
  final int quietStartHour;
  final int quietEndHour;

  const NotificationSettings({
    // Morning Briefing - default aktif jam 5 pagi
    this.morningBriefingEnabled = true,
    this.morningBriefingHour = 5,
    this.morningBriefingMinute = 0,
    // Weather Alerts - default semua aktif
    this.heavyRainAlertEnabled = true,
    this.strongWindAlertEnabled = true,
    this.thunderstormAlertEnabled = true,
    // Farming Reminders - default semua aktif
    this.fertilizationReminderEnabled = true,
    this.smartWateringEnabled = true,
    this.pestWarningEnabled = true,
    // Calendar Reminders - default semua aktif
    this.reminder1DayBefore = true,
    this.reminder1HourBefore = true,
    this.reminderAtTime = true,
    // Quiet Hours - default aktif 22:00 - 05:00
    this.quietModeEnabled = true,
    this.quietStartHour = 22,
    this.quietEndHour = 5,
  });

  /// Create from JSON (for cache loading)
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      morningBriefingEnabled: json['morningBriefingEnabled'] ?? true,
      morningBriefingHour: json['morningBriefingHour'] ?? 5,
      morningBriefingMinute: json['morningBriefingMinute'] ?? 0,
      heavyRainAlertEnabled: json['heavyRainAlertEnabled'] ?? true,
      strongWindAlertEnabled: json['strongWindAlertEnabled'] ?? true,
      thunderstormAlertEnabled: json['thunderstormAlertEnabled'] ?? true,
      fertilizationReminderEnabled:
          json['fertilizationReminderEnabled'] ?? true,
      smartWateringEnabled: json['smartWateringEnabled'] ?? true,
      pestWarningEnabled: json['pestWarningEnabled'] ?? true,
      reminder1DayBefore: json['reminder1DayBefore'] ?? true,
      reminder1HourBefore: json['reminder1HourBefore'] ?? true,
      reminderAtTime: json['reminderAtTime'] ?? true,
      quietModeEnabled: json['quietModeEnabled'] ?? true,
      quietStartHour: json['quietStartHour'] ?? 22,
      quietEndHour: json['quietEndHour'] ?? 5,
    );
  }

  /// Convert to JSON (for cache saving)
  Map<String, dynamic> toJson() {
    return {
      'morningBriefingEnabled': morningBriefingEnabled,
      'morningBriefingHour': morningBriefingHour,
      'morningBriefingMinute': morningBriefingMinute,
      'heavyRainAlertEnabled': heavyRainAlertEnabled,
      'strongWindAlertEnabled': strongWindAlertEnabled,
      'thunderstormAlertEnabled': thunderstormAlertEnabled,
      'fertilizationReminderEnabled': fertilizationReminderEnabled,
      'smartWateringEnabled': smartWateringEnabled,
      'pestWarningEnabled': pestWarningEnabled,
      'reminder1DayBefore': reminder1DayBefore,
      'reminder1HourBefore': reminder1HourBefore,
      'reminderAtTime': reminderAtTime,
      'quietModeEnabled': quietModeEnabled,
      'quietStartHour': quietStartHour,
      'quietEndHour': quietEndHour,
    };
  }

  /// Create a copy with updated values
  NotificationSettings copyWith({
    bool? morningBriefingEnabled,
    int? morningBriefingHour,
    int? morningBriefingMinute,
    bool? heavyRainAlertEnabled,
    bool? strongWindAlertEnabled,
    bool? thunderstormAlertEnabled,
    bool? fertilizationReminderEnabled,
    bool? smartWateringEnabled,
    bool? pestWarningEnabled,
    bool? reminder1DayBefore,
    bool? reminder1HourBefore,
    bool? reminderAtTime,
    bool? quietModeEnabled,
    int? quietStartHour,
    int? quietEndHour,
  }) {
    return NotificationSettings(
      morningBriefingEnabled:
          morningBriefingEnabled ?? this.morningBriefingEnabled,
      morningBriefingHour: morningBriefingHour ?? this.morningBriefingHour,
      morningBriefingMinute:
          morningBriefingMinute ?? this.morningBriefingMinute,
      heavyRainAlertEnabled:
          heavyRainAlertEnabled ?? this.heavyRainAlertEnabled,
      strongWindAlertEnabled:
          strongWindAlertEnabled ?? this.strongWindAlertEnabled,
      thunderstormAlertEnabled:
          thunderstormAlertEnabled ?? this.thunderstormAlertEnabled,
      fertilizationReminderEnabled:
          fertilizationReminderEnabled ?? this.fertilizationReminderEnabled,
      smartWateringEnabled: smartWateringEnabled ?? this.smartWateringEnabled,
      pestWarningEnabled: pestWarningEnabled ?? this.pestWarningEnabled,
      reminder1DayBefore: reminder1DayBefore ?? this.reminder1DayBefore,
      reminder1HourBefore: reminder1HourBefore ?? this.reminder1HourBefore,
      reminderAtTime: reminderAtTime ?? this.reminderAtTime,
      quietModeEnabled: quietModeEnabled ?? this.quietModeEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietEndHour: quietEndHour ?? this.quietEndHour,
    );
  }

  /// Check if current time is within quiet hours
  bool isQuietTime() {
    if (!quietModeEnabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;

    // Handle overnight quiet hours (e.g., 22:00 - 05:00)
    if (quietStartHour > quietEndHour) {
      return currentHour >= quietStartHour || currentHour < quietEndHour;
    } else {
      return currentHour >= quietStartHour && currentHour < quietEndHour;
    }
  }
}
