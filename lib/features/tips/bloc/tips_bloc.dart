import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:petani_maju/data/repositories/tips_repository.dart';

part 'tips_event.dart';
part 'tips_state.dart';

/// BLoC untuk mengelola state halaman Tips Pertanian
class TipsBloc extends Bloc<TipsEvent, TipsState> {
  final TipsRepository _tipsRepository;

  TipsBloc({
    required TipsRepository tipsRepository,
  })  : _tipsRepository = tipsRepository,
        super(TipsInitial()) {
    on<LoadTips>(_onLoadTips);
    on<RefreshTips>(_onRefreshTips);
    on<SearchTips>(_onSearchTips);
    on<FilterTipsByCategory>(_onFilterByCategory);
  }

  /// Handle load tips
  Future<void> _onLoadTips(
    LoadTips event,
    Emitter<TipsState> emit,
  ) async {
    emit(TipsLoading());

    try {
      final tips = await _tipsRepository.fetchTips();
      emit(TipsLoaded(tips: tips, filteredTips: tips));
    } catch (e) {
      debugPrint('TipsBloc Error: $e');
      emit(TipsError(message: e.toString()));
    }
  }

  /// Handle refresh tips
  Future<void> _onRefreshTips(
    RefreshTips event,
    Emitter<TipsState> emit,
  ) async {
    try {
      final tips = await _tipsRepository.fetchTips(forceRefresh: true);

      final currentState = state;
      String category = 'Semua';
      String query = '';

      if (currentState is TipsLoaded) {
        category = currentState.selectedCategory;
        query = currentState.searchQuery;
      }

      final filtered = _applyFilters(tips, category, query);

      emit(TipsLoaded(
        tips: tips,
        filteredTips: filtered,
        selectedCategory: category,
        searchQuery: query,
      ));
    } catch (e) {
      debugPrint('TipsBloc Refresh Error: $e');
    }
  }

  void _onSearchTips(
    SearchTips event,
    Emitter<TipsState> emit,
  ) {
    final currentState = state;
    if (currentState is TipsLoaded) {
      final filtered = _applyFilters(
        currentState.tips,
        currentState.selectedCategory,
        event.query,
      );
      emit(currentState.copyWith(
        filteredTips: filtered,
        searchQuery: event.query,
      ));
    }
  }

  void _onFilterByCategory(
    FilterTipsByCategory event,
    Emitter<TipsState> emit,
  ) {
    final currentState = state;
    if (currentState is TipsLoaded) {
      final filtered = _applyFilters(
        currentState.tips,
        event.category,
        currentState.searchQuery,
      );
      emit(currentState.copyWith(
        filteredTips: filtered,
        selectedCategory: event.category,
      ));
    }
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> data,
    String category,
    String query,
  ) {
    var result = data;

    if (category != 'Semua') {
      result = result.where((t) => t['category'] == category).toList();
    }

    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result = result.where((t) {
        final title = (t['title'] ?? '').toString().toLowerCase();
        return title.contains(lowerQuery);
      }).toList();
    }

    return result;
  }
}
