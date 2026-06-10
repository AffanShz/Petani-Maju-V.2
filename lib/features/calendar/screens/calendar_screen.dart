// lib/features/calendar/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:petani_maju/features/calendar/bloc/calendar_bloc.dart';
import 'package:petani_maju/core/services/notification_service.dart';
import 'package:petani_maju/core/services/notification_scheduler.dart';
import 'package:petani_maju/widgets/custom_time_picker.dart';
import 'package:petani_maju/core/constants/monthly_activities.dart';

// ==========================================
// 1. WIDGET PICKER JAM DENGAN TOMBOL
// ==========================================

// ==========================================
// 2. MAIN SCREEN - REFACTORED WITH BLOC
// ==========================================

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _hasRescheduledNotifications = false;

  /// Reschedule notifications for all existing schedules
  Future<void> _rescheduleAllNotifications(
      List<Map<String, dynamic>> schedules) async {
    if (_hasRescheduledNotifications) return;
    _hasRescheduledNotifications = true;

    debugPrint(
        '🔄 Rescheduling notifications for ${schedules.length} existing schedules...');

    for (final schedule in schedules) {
      try {
        final id = schedule['id'] as int;
        final name = schedule['nama_tanaman'] as String;
        final dateTimeStr = schedule['tanggal_tanam'] as String;
        final dateTime = DateTime.parse(dateTimeStr);

        // Only reschedule for future events
        if (dateTime.isAfter(DateTime.now())) {
          final time = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
          await _scheduleNotifications(id, name, dateTime, time);
        } else {
          debugPrint('   ⏭️ Skipping past schedule: $name (ID: $id)');
        }
      } catch (e) {
        debugPrint('   ❌ Error rescheduling: $e');
      }
    }

    debugPrint('✅ Notification rescheduling complete');

    // Print all pending notifications for debugging
    await NotificationService().printPendingNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(context, isEdit: false),
        backgroundColor: Colors.green,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<CalendarBloc, CalendarState>(
        listener: (context, state) async {
          if (state is CalendarOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          // Auto-reschedule notifications for existing schedules when loaded
          if (state is CalendarLoaded) {
            _rescheduleAllNotifications(state.schedules);
          }

          // Handle notification scheduling when new schedule is added
          if (state is CalendarScheduleAdded) {
            final time = TimeOfDay(
              hour: state.tanggalTanam.hour,
              minute: state.tanggalTanam.minute,
            );
            _scheduleNotifications(
              state.newScheduleId,
              state.namaTanaman,
              state.tanggalTanam,
              time,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('calendar.add_success'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CalendarScheduleUpdated) {
            final time = TimeOfDay(
              hour: state.tanggalTanam.hour,
              minute: state.tanggalTanam.minute,
            );
            // Cancel old notifications first (id*10+0, +1, +2)
            final scheduler = NotificationScheduler();
            await scheduler.cancelCalendarReminders(state.scheduleId);

            // Schedule new notifications
            _scheduleNotifications(
              state.scheduleId,
              state.namaTanaman,
              state.tanggalTanam,
              time,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('calendar.update_success'.tr()),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CalendarInitial || state is CalendarLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CalendarLoaded) {
            return _buildContent(context, state);
          }

          // Also render for CalendarScheduleAdded (it has schedules data)
          if (state is CalendarScheduleAdded) {
            // Convert to CalendarLoaded for rendering
            final loadedState = CalendarLoaded(
              schedules: state.schedules,
              selectedDate: state.selectedDate,
              focusedDate: state.focusedDate,
            );
            return _buildContent(context, loadedState);
          }

          if (state is CalendarScheduleUpdated) {
            // Convert to CalendarLoaded for rendering
            final loadedState = CalendarLoaded(
              schedules: state.schedules,
              selectedDate: state.selectedDate,
              focusedDate: state.focusedDate,
            );
            return _buildContent(context, loadedState);
          }

          if (state is CalendarError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CalendarBloc>().add(LoadSchedules());
                    },
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, CalendarLoaded state) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            Center(
              child: Text(
                'calendar.title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. CALENDAR CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(bottom: 12),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: state.focusedDate,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) =>
                    isSameDay(state.selectedDate, day),
                eventLoader: (day) => state.getEventsForDay(day),
                locale: context.locale.languageCode, // Set locale for calendar
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, size: 20),
                  rightChevronIcon: Icon(Icons.chevron_right, size: 20),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  context
                      .read<CalendarBloc>()
                      .add(SelectDate(date: selectedDay));
                },
                onPageChanged: (focusedDay) {
                  context
                      .read<CalendarBloc>()
                      .add(PageChanged(focusedDay: focusedDay));
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  outsideDaysVisible: false,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. KEGIATAN HARI INI
            Text(
              'calendar.today_activities'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildEventsList(context, state),

            const SizedBox(height: 24),

            // 4. REKOMENDASI AKTIVITAS
            Text(
              'calendar.monthly_recommendations'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildRecommendationCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, CalendarLoaded state) {
    final events = state.getEventsForDay(state.selectedDate);

    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'calendar.no_schedule'.tr(),
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        String timeString = '-';
        try {
          final dt = DateTime.parse(event['tanggal_tanam']);
          timeString = DateFormat('HH:mm').format(dt);
        } catch (_) {}

        Color accentColor = index % 2 == 0 ? Colors.green : Colors.orange;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                event['nama_tanaman'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                timeString,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event['catatan'] ?? '-',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.edit, size: 20, color: Colors.blue),
                      onPressed: () => _showScheduleDialog(context,
                          isEdit: true, event: event),
                      padding: const EdgeInsets.all(0),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: () => _confirmDelete(context, event['id']),
                      padding: const EdgeInsets.all(0),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationCard() {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        int currentMonth = DateTime.now().month;
        if (state is CalendarLoaded) {
          currentMonth = state.focusedDate.month;
        }

        final activities = MonthlyActivities.getData()[currentMonth] ??
            MonthlyActivities.getData()[1]!;

        final title = activities['title'] as String;
        final items = activities['items'] as List<String>;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.spa, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildRecommendationItem(item),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6.0),
          child: Icon(Icons.circle, size: 6, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('calendar.delete_title'.tr()),
        content: Text('calendar.delete_confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Delete via BLoC
              context.read<CalendarBloc>().add(DeleteSchedule(id: id));

              // Cancel notifications
              final notif = NotificationService();
              await notif.cancelNotification(id * 10 + 0);
              await notif.cancelNotification(id * 10 + 1);
              await notif.cancelNotification(id * 10 + 2);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('common.delete'.tr(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. DIALOG INPUT JADWAL
  // ==========================================

  void _showScheduleDialog(BuildContext scaffoldContext,
      {required bool isEdit, Map<String, dynamic>? event}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 0);

    if (isEdit && event != null) {
      nameController.text = event['nama_tanaman'];
      noteController.text = event['catatan'] ?? '';
      try {
        DateTime dt = DateTime.parse(event['tanggal_tanam']);
        selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: scaffoldContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isEdit
                          ? 'calendar.edit_schedule'.tr()
                          : 'calendar.add_schedule'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildModernInput(
                      controller: nameController,
                      label: 'calendar.plant_name_label'.tr(),
                      icon: Icons.eco_outlined,
                      hint: 'calendar.plant_name_hint'.tr(),
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      controller: noteController,
                      label: 'calendar.note_label'.tr(),
                      icon: Icons.note_alt_outlined,
                      hint: 'calendar.note_hint'.tr(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "calendar.time_label".tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: CustomTimePicker(
                        initialTime: selectedTime,
                        onTimeChanged: (newTime) {
                          selectedTime = newTime;
                          setStateModal(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.grey[600],
                            ),
                            child: Text('common.cancel'.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.isNotEmpty) {
                                // Get selected date from BLoC state
                                final blocState =
                                    scaffoldContext.read<CalendarBloc>().state;
                                DateTime selectedDate = DateTime.now();
                                if (blocState is CalendarLoaded) {
                                  selectedDate = blocState.selectedDate;
                                }

                                final DateTime finalDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );

                                if (isEdit && event != null) {
                                  int scheduleId = event['id'];

                                  // Update via BLoC
                                  scaffoldContext.read<CalendarBloc>().add(
                                        UpdateSchedule(
                                          id: scheduleId,
                                          namaTanaman: nameController.text,
                                          tanggalTanam: finalDateTime,
                                          catatan: noteController.text,
                                        ),
                                      );

                                  // Cancel old notifications
                                  final notif = NotificationService();
                                  await notif
                                      .cancelNotification(scheduleId * 10 + 0);
                                  await notif
                                      .cancelNotification(scheduleId * 10 + 1);
                                  await notif
                                      .cancelNotification(scheduleId * 10 + 2);

                                  // Schedule new notifications
                                  await _scheduleNotifications(
                                    scheduleId,
                                    nameController.text,
                                    finalDateTime,
                                    selectedTime,
                                  );
                                } else {
                                  // Add via BLoC
                                  scaffoldContext.read<CalendarBloc>().add(
                                        AddSchedule(
                                          namaTanaman: nameController.text,
                                          tanggalTanam: finalDateTime,
                                          catatan: noteController.text,
                                        ),
                                      );

                                  // Note: For new schedules, we'd need the ID from bloc
                                  // For now, notifications for new items need manual handling
                                }

                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'calendar.save_schedule'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _scheduleNotifications(
    int scheduleId,
    String plantName,
    DateTime dateTime,
    TimeOfDay time,
  ) async {
    try {
      final notif = NotificationService();
      // Ensure notification service is initialized (critical for release builds)
      await notif.init();

      final timeFormatted =
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

      debugPrint(
          '📅 Scheduling notifications for: $plantName at $dateTime (ID: $scheduleId)');

      // 1. Notifikasi tepat waktu
      final atTimeDate = dateTime;
      debugPrint('   ⏰ At time: $atTimeDate');
      if (atTimeDate.isAfter(DateTime.now())) {
        await notif.scheduleNotification(
          id: scheduleId * 10 + 0,
          title: '🌱 Waktunya: $plantName',
          body: 'Sekarang saatnya kegiatan $plantName.',
          scheduledDate: atTimeDate,
        );
        debugPrint('   ✅ At-time notification scheduled');
      } else {
        debugPrint('   ⚠️ At-time skipped (already passed)');
      }

      // 2. Notifikasi 1 hari (24 jam) sebelum
      final oneDayBefore = dateTime.subtract(const Duration(days: 1));
      debugPrint('   📆 1 day before: $oneDayBefore');
      if (oneDayBefore.isAfter(DateTime.now())) {
        await notif.scheduleNotification(
          id: scheduleId * 10 + 1,
          title: '📅 Pengingat Besok',
          body: 'Besok jam $timeFormatted ada kegiatan: $plantName',
          scheduledDate: oneDayBefore,
        );
        debugPrint('   ✅ 1-day-before notification scheduled');
      } else {
        debugPrint('   ⚠️ 1-day-before skipped (already passed)');
      }

      // 3. Notifikasi 1 jam sebelum
      final oneHourBefore = dateTime.subtract(const Duration(hours: 1));
      debugPrint('   ⏱️ 1 hour before: $oneHourBefore');
      if (oneHourBefore.isAfter(DateTime.now())) {
        await notif.scheduleNotification(
          id: scheduleId * 10 + 2,
          title: '⏰ 1 Jam Lagi!',
          body: 'Jam $timeFormatted ada kegiatan: $plantName',
          scheduledDate: oneHourBefore,
        );
        debugPrint('   ✅ 1-hour-before notification scheduled');
      } else {
        debugPrint('   ⚠️ 1-hour-before skipped (already passed)');
      }

      debugPrint('📅 Notification scheduling complete for: $plantName');
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
      // Don't rethrow - we don't want notification failures to crash the app
    }
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
