part of 'calendar_bloc.dart';

/// States untuk CalendarBloc
abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

/// State awal
class CalendarInitial extends CalendarState {}

/// State saat sedang memuat data
class CalendarLoading extends CalendarState {}

/// State saat data berhasil dimuat
class CalendarLoaded extends CalendarState {
  /// Semua jadwal tanam
  final List<Map<String, dynamic>> schedules;

  /// Tanggal yang sedang dipilih
  final DateTime selectedDate;

  /// Tanggal fokus kalender
  final DateTime focusedDate;

  const CalendarLoaded({
    required this.schedules,
    required this.selectedDate,
    required this.focusedDate,
  });

  @override
  List<Object?> get props => [schedules, selectedDate, focusedDate];

  /// Get events untuk tanggal tertentu
  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    return schedules.where((schedule) {
      final scheduleDate = DateTime.parse(schedule['tanggal_tanam']);
      return scheduleDate.year == day.year &&
          scheduleDate.month == day.month &&
          scheduleDate.day == day.day;
    }).toList();
  }

  CalendarLoaded copyWith({
    List<Map<String, dynamic>>? schedules,
    DateTime? selectedDate,
    DateTime? focusedDate,
  }) {
    return CalendarLoaded(
      schedules: schedules ?? this.schedules,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedDate: focusedDate ?? this.focusedDate,
    );
  }
}

/// State saat operasi berhasil (add/update/delete)
class CalendarOperationSuccess extends CalendarState {
  final String message;

  const CalendarOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State saat jadwal baru berhasil ditambahkan (dengan ID untuk notifikasi)
class CalendarScheduleAdded extends CalendarState {
  final int newScheduleId;
  final String namaTanaman;
  final DateTime tanggalTanam;
  final List<Map<String, dynamic>> schedules;
  final DateTime selectedDate;
  final DateTime focusedDate;

  const CalendarScheduleAdded({
    required this.newScheduleId,
    required this.namaTanaman,
    required this.tanggalTanam,
    required this.schedules,
    required this.selectedDate,
    required this.focusedDate,
  });

  @override
  List<Object?> get props =>
      [newScheduleId, namaTanaman, tanggalTanam, schedules];
}

/// State saat jadwal berhasil diperbarui (dengan ID untuk update notifikasi)
class CalendarScheduleUpdated extends CalendarState {
  final int scheduleId;
  final String namaTanaman;
  final DateTime tanggalTanam;
  final List<Map<String, dynamic>> schedules;
  final DateTime selectedDate;
  final DateTime focusedDate;

  const CalendarScheduleUpdated({
    required this.scheduleId,
    required this.namaTanaman,
    required this.tanggalTanam,
    required this.schedules,
    required this.selectedDate,
    required this.focusedDate,
  });

  @override
  List<Object?> get props => [scheduleId, namaTanaman, tanggalTanam, schedules];
}

/// State saat terjadi error
class CalendarError extends CalendarState {
  final String message;

  const CalendarError({required this.message});

  @override
  List<Object?> get props => [message];
}
