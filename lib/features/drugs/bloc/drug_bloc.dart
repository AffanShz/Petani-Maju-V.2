import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:petani_maju/data/repositories/drug_repository.dart';

part 'drug_event.dart';
part 'drug_state.dart';

/// BLoC untuk mengelola state halaman Obat Tanaman
class DrugBloc extends Bloc<DrugEvent, DrugState> {
  final DrugRepository _drugRepository;

  DrugBloc({
    required DrugRepository drugRepository,
  })  : _drugRepository = drugRepository,
        super(DrugInitial()) {
    on<LoadDrugs>(_onLoadDrugs);
    on<RefreshDrugs>(_onRefreshDrugs);
    on<SearchDrugs>(_onSearchDrugs);
    on<FilterDrugsByCategory>(_onFilterByCategory);
  }

  /// Handle load drugs
  Future<void> _onLoadDrugs(
    LoadDrugs event,
    Emitter<DrugState> emit,
  ) async {
    emit(DrugLoading());

    try {
      final drugs = await _drugRepository.fetchDrugs();
      emit(DrugLoaded(
        allDrugs: drugs,
        filteredDrugs: drugs,
      ));
    } catch (e) {
      debugPrint('DrugBloc Error: $e');
      emit(const DrugError(
        message:
            'Gagal memuat data obat tanaman. Pastikan file katalog_obat_tanaman.json tersedia dan format JSON benar.',
      ));
    }
  }

  /// Handle refresh drugs
  Future<void> _onRefreshDrugs(
    RefreshDrugs event,
    Emitter<DrugState> emit,
  ) async {
    try {
      final drugs = await _drugRepository.fetchDrugs(forceRefresh: true);

      // Pertahankan filter saat ini jika ada
      final currentState = state;
      String category = 'Semua';
      String query = '';

      if (currentState is DrugLoaded) {
        category = currentState.selectedCategory;
        query = currentState.searchQuery;
      }

      final filtered = _applyFilters(drugs, category, query);

      emit(DrugLoaded(
        allDrugs: drugs,
        filteredDrugs: filtered,
        selectedCategory: category,
        searchQuery: query,
      ));
    } catch (e) {
      debugPrint('DrugBloc Refresh Error: $e');
      // Tetap di state sekarang jika refresh gagal
    }
  }

  /// Handle search drugs
  Future<void> _onSearchDrugs(
    SearchDrugs event,
    Emitter<DrugState> emit,
  ) async {
    final currentState = state;

    if (currentState is DrugLoaded) {
      // Filter dari data yang sudah ada
      final filtered = _applyFilters(
        currentState.allDrugs,
        currentState.selectedCategory,
        event.query,
      );

      emit(currentState.copyWith(
        filteredDrugs: filtered,
        searchQuery: event.query,
      ));
    }
  }

  /// Handle filter by category
  void _onFilterByCategory(
    FilterDrugsByCategory event,
    Emitter<DrugState> emit,
  ) {
    final currentState = state;

    if (currentState is DrugLoaded) {
      final filtered = _applyFilters(
        currentState.allDrugs,
        event.category,
        currentState.searchQuery,
      );

      emit(currentState.copyWith(
        filteredDrugs: filtered,
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
      result = result.where((d) => d['kategori'] == category).toList();
    }

    // Filter by search query (nama, bahan aktif, sasaran, produsen, tanaman)
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result = result.where((drug) {
        final name = drug['nama']?.toString().toLowerCase() ?? '';
        final bahan = drug['bahan_aktif']?.toString().toLowerCase() ?? '';
        final sasaran = drug['sasaran'] is List
            ? (drug['sasaran'] as List).join(' ').toLowerCase()
            : drug['sasaran']?.toString().toLowerCase() ?? '';
        final produsen = drug['produsen']?.toString().toLowerCase() ?? '';
        final tanaman = drug['tanaman'] is List
            ? (drug['tanaman'] as List).join(' ').toLowerCase()
            : drug['tanaman']?.toString().toLowerCase() ?? '';

        return name.contains(lowerQuery) ||
            bahan.contains(lowerQuery) ||
            sasaran.contains(lowerQuery) ||
            produsen.contains(lowerQuery) ||
            tanaman.contains(lowerQuery);
      }).toList();
    }

    return result;
  }
}
