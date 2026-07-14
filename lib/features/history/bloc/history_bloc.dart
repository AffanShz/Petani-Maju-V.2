import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository _historyRepository;

  HistoryBloc({required HistoryRepository historyRepository})
      : _historyRepository = historyRepository,
        super(const HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<DeleteHistoryItem>(_onDeleteHistoryItem);
    on<DeleteAllHistory>(_onDeleteAllHistory);
  }

  Future<void> _onLoadHistory(
      LoadHistory event, Emitter<HistoryState> emit) async {
    emit(const HistoryLoading());
    try {
      final items = await _historyRepository.getHistory();
      emit(HistoryLoaded(items));
    } catch (e) {
      debugPrint('HistoryBloc Error: $e');
      emit(const HistoryError('Gagal memuat riwayat. Periksa koneksi internet.'));
    }
  }

  Future<void> _onDeleteHistoryItem(
      DeleteHistoryItem event, Emitter<HistoryState> emit) async {
    try {
      await _historyRepository.deleteHistoryItem(event.id);
      // Reload after delete
      final items = await _historyRepository.getHistory();
      emit(HistoryLoaded(items));
    } catch (e) {
      debugPrint('HistoryBloc Delete Error: $e');
      emit(const HistoryError('Gagal menghapus riwayat.'));
    }
  }

  Future<void> _onDeleteAllHistory(
      DeleteAllHistory event, Emitter<HistoryState> emit) async {
    try {
      await _historyRepository.deleteAllHistory();
      emit(const HistoryLoaded([]));
    } catch (e) {
      debugPrint('HistoryBloc DeleteAll Error: $e');
      emit(const HistoryError('Gagal menghapus semua riwayat.'));
    }
  }
}
