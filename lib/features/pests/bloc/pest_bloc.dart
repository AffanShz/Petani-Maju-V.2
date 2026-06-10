import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:petani_maju/data/repositories/pest_repository.dart';

part 'pest_event.dart';
part 'pest_state.dart';

/// BLoC untuk mengelola state halaman Hama/Penyakit
class PestBloc extends Bloc<PestEvent, PestState> {
  final PestRepository _pestRepository;

  PestBloc({
    required PestRepository pestRepository,
  })  : _pestRepository = pestRepository,
        super(PestInitial()) {
    on<LoadPests>(_onLoadPests);
    on<RefreshPests>(_onRefreshPests);
    on<SearchPests>(_onSearchPests);
    on<FilterPestsByCategory>(_onFilterByCategory);
  }

  /// Handle load pests
  Future<void> _onLoadPests(
    LoadPests event,
    Emitter<PestState> emit,
  ) async {
    emit(PestLoading());

    try {
      final pests = await _pestRepository.fetchPests();
      emit(PestLoaded(
        allPests: pests,
        filteredPests: pests,
      ));
    } catch (e) {
      debugPrint('PestBloc Error: $e');
      emit(PestError(message: e.toString()));
    }
  }

  /// Handle refresh pests
  Future<void> _onRefreshPests(
    RefreshPests event,
    Emitter<PestState> emit,
  ) async {
    try {
      final pests = await _pestRepository.fetchPests(forceRefresh: true);

      // Pertahankan filter saat ini jika ada
      final currentState = state;
      String category = 'Semua';
      String query = '';

      if (currentState is PestLoaded) {
        category = currentState.selectedCategory;
        query = currentState.searchQuery;
      }

      final filtered = _applyFilters(pests, category, query);

      emit(PestLoaded(
        allPests: pests,
        filteredPests: filtered,
        selectedCategory: category,
        searchQuery: query,
      ));
    } catch (e) {
      debugPrint('PestBloc Refresh Error: $e');
      // Tetap di state sekarang jika refresh gagal
    }
  }

  /// Handle search pests
  Future<void> _onSearchPests(
    SearchPests event,
    Emitter<PestState> emit,
  ) async {
    final currentState = state;

    if (currentState is PestLoaded) {
      // Filter dari data yang sudah ada
      final filtered = _applyFilters(
        currentState.allPests,
        currentState.selectedCategory,
        event.query,
      );

      emit(currentState.copyWith(
        filteredPests: filtered,
        searchQuery: event.query,
      ));
    } else {
      // Load dulu jika belum ada data
      emit(PestLoading());

      try {
        final pests = await _pestRepository.fetchPests(query: event.query);
        emit(PestLoaded(
          allPests: pests,
          filteredPests: pests,
          searchQuery: event.query,
        ));
      } catch (e) {
        emit(PestError(message: e.toString()));
      }
    }
  }

  /// Handle filter by category
  void _onFilterByCategory(
    FilterPestsByCategory event,
    Emitter<PestState> emit,
  ) {
    final currentState = state;

    if (currentState is PestLoaded) {
      final filtered = _applyFilters(
        currentState.allPests,
        event.category,
        currentState.searchQuery,
      );

      emit(currentState.copyWith(
        filteredPests: filtered,
        selectedCategory: event.category,
      ));
    }
  }

  /// Apply filters ke data
  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> data,
    String category,
    String query,
  ) {
    var result = data;

    // Filter by category
    if (category != 'Semua') {
      result = result.where((p) => p['kategori'] == category).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result = result.where((p) {
        final nama = (p['nama'] ?? '').toString().toLowerCase();
        return nama.contains(lowerQuery);
      }).toList();
    }

    return result;
  }
}
