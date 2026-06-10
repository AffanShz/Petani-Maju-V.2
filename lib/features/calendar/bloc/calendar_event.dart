part of 'calendar_bloc.dart';

/// Events untuk CalendarBloc
abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memuat jadwal (saat init)
class LoadSchedules extends CalendarEvent {}

/// Event untuk menambah jadwal baru
class AddSchedule extends CalendarEvent {
  final String namaTanaman;
  final DateTime tanggalTanam;
  final String? catatan;

  const AddSchedule({
    required this.namaTanaman,
    required this.tanggalTanam,
    this.catatan,
  });

  @override
  List<Object?> get props => [namaTanaman, tanggalTanam, catatan];
}

/// Event untuk update jadwal
class UpdateSchedule extends CalendarEvent {
  final int id;
  final String namaTanaman;
  final DateTime tanggalTanam;
  final String? catatan;

  const UpdateSchedule({
    required this.id,
    required this.namaTanaman,
    required this.tanggalTanam,
    this.catatan,
  });

  @override
  List<Object?> get props => [id, namaTanaman, tanggalTanam, catatan];
}

/// Event untuk menghapus jadwal
class DeleteSchedule extends CalendarEvent {
  final int id;

  const DeleteSchedule({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Event saat tanggal dipilih di kalender
class SelectDate extends CalendarEvent {
  final DateTime date;

  const SelectDate({required this.date});

  @override
  List<Object?> get props => [date];
}

/// Event saat halaman kalender berubah (ganti bulan)
class PageChanged extends CalendarEvent {
  final DateTime focusedDay;

  const PageChanged({required this.focusedDay});

  @override
  List<Object?> get props => [focusedDay];
}
