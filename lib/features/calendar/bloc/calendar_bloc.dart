import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:petani_maju/data/repositories/calendar_repository.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

/// BLoC untuk mengelola state halaman Kalender Tanam
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarRepository _calendarRepository;

  CalendarBloc({
    required CalendarRepository calendarRepository,
  })  : _calendarRepository = calendarRepository,
        super(CalendarInitial()) {
    on<LoadSchedules>(_onLoadSchedules);
    on<AddSchedule>(_onAddSchedule);
    on<UpdateSchedule>(_onUpdateSchedule);
    on<DeleteSchedule>(_onDeleteSchedule);

    on<SelectDate>(_onSelectDate);
    on<PageChanged>(_onPageChanged);
  }

  /// Handle load schedules
  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());

    try {
      final schedules = await _calendarRepository.fetchSchedules();
      final now = DateTime.now();

      emit(CalendarLoaded(
        schedules: schedules,
        selectedDate: now,
        focusedDate: now,
      ));
    } catch (e) {
      debugPrint('CalendarBloc Error: $e');
      emit(CalendarError(message: e.toString()));
    }
  }

  /// Handle add schedule
  Future<void> _onAddSchedule(
    AddSchedule event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      // Get ID from repository
      final newId = await _calendarRepository.addSchedule(
        namaTanaman: event.namaTanaman,
        tanggalTanam: event.tanggalTanam,
        catatan: event.catatan,
      );

      // Reload schedules setelah add
      final schedules = await _calendarRepository.fetchSchedules();

      final currentState = state;
      final selectedDate = currentState is CalendarLoaded
          ? currentState.selectedDate
          : DateTime.now();
      final focusedDate = currentState is CalendarLoaded
          ? currentState.focusedDate
          : DateTime.now();

      // Emit CalendarScheduleAdded first for notification scheduling
      emit(CalendarScheduleAdded(
        newScheduleId: newId,
        namaTanaman: event.namaTanaman,
        tanggalTanam: event.tanggalTanam,
        schedules: schedules,
        selectedDate: selectedDate,
        focusedDate: focusedDate,
      ));

      // Then emit CalendarLoaded to restore normal state
      // This fixes the issue where calendar becomes stuck after adding
      await Future.delayed(const Duration(milliseconds: 100));
      emit(CalendarLoaded(
        schedules: schedules,
        selectedDate: selectedDate,
        focusedDate: focusedDate,
      ));
    } catch (e) {
      debugPrint('CalendarBloc Add Error: $e');
      emit(CalendarError(message: 'Gagal menambah jadwal: $e'));
    }
  }

  /// Handle update schedule
  Future<void> _onUpdateSchedule(
    UpdateSchedule event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await _calendarRepository.updateSchedule(
        id: event.id,
        namaTanaman: event.namaTanaman,
        tanggalTanam: event.tanggalTanam,
        catatan: event.catatan,
      );

      // Reload schedules setelah update
      final schedules = await _calendarRepository.fetchSchedules();

      final currentState = state;
      final selectedDate = currentState is CalendarLoaded
          ? currentState.selectedDate
          : DateTime.now();
      final focusedDate = currentState is CalendarLoaded
          ? currentState.focusedDate
          : DateTime.now();

      // Emit CalendarScheduleUpdated first for notification rescheduling
      emit(CalendarScheduleUpdated(
        scheduleId: event.id,
        namaTanaman: event.namaTanaman,
        tanggalTanam: event.tanggalTanam,
        schedules: schedules,
        selectedDate: selectedDate,
        focusedDate: focusedDate,
      ));

      // Then emit CalendarLoaded to restore normal state
      await Future.delayed(const Duration(milliseconds: 100));
      emit(CalendarLoaded(
        schedules: schedules,
        selectedDate: selectedDate,
        focusedDate: focusedDate,
      ));
    } catch (e) {
      debugPrint('CalendarBloc Update Error: $e');
      emit(CalendarError(message: 'Gagal mengupdate jadwal: $e'));
    }
  }

  /// Handle delete schedule
  Future<void> _onDeleteSchedule(
    DeleteSchedule event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await _calendarRepository.deleteSchedule(event.id);

      // Reload schedules setelah delete
      final schedules = await _calendarRepository.fetchSchedules();

      final currentState = state;
      if (currentState is CalendarLoaded) {
        emit(currentState.copyWith(schedules: schedules));
      }
    } catch (e) {
      debugPrint('CalendarBloc Delete Error: $e');
      emit(CalendarError(message: 'Gagal menghapus jadwal: $e'));
    }
  }

  /// Handle select date
  void _onSelectDate(
    SelectDate event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      emit(currentState.copyWith(
        selectedDate: event.date,
        focusedDate: event.date,
      ));
    }
  }

  /// Handle page changed (month swiping)
  void _onPageChanged(
    PageChanged event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      emit(currentState.copyWith(
        focusedDate: event.focusedDay,
      ));
    }
  }
}
