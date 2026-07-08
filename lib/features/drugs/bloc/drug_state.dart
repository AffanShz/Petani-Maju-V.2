part of 'drug_bloc.dart';

/// States untuk DrugBloc
abstract class DrugState extends Equatable {
  const DrugState();

  @override
  List<Object?> get props => [];
}

/// State awal
class DrugInitial extends DrugState {}

/// State saat sedang memuat data
class DrugLoading extends DrugState {}

/// State saat data berhasil dimuat
class DrugLoaded extends DrugState {
  /// Semua data obat (tanpa filter)
  final List<Map<String, dynamic>> allDrugs;

  /// Data obat yang sudah difilter
  final List<Map<String, dynamic>> filteredDrugs;

  /// Kategori yang sedang dipilih
  final String selectedCategory;

  /// Query pencarian saat ini
  final String searchQuery;

  const DrugLoaded({
    required this.allDrugs,
    required this.filteredDrugs,
    this.selectedCategory = 'Semua',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props =>
      [allDrugs, filteredDrugs, selectedCategory, searchQuery];

  DrugLoaded copyWith({
    List<Map<String, dynamic>>? allDrugs,
    List<Map<String, dynamic>>? filteredDrugs,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return DrugLoaded(
      allDrugs: allDrugs ?? this.allDrugs,
      filteredDrugs: filteredDrugs ?? this.filteredDrugs,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// State saat terjadi error
class DrugError extends DrugState {
  final String message;

  const DrugError({required this.message});

  @override
  List<Object?> get props => [message];
}
