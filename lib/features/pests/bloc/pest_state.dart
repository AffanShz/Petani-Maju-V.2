part of 'pest_bloc.dart';

/// States untuk PestBloc
abstract class PestState extends Equatable {
  const PestState();

  @override
  List<Object?> get props => [];
}

/// State awal
class PestInitial extends PestState {}

/// State saat sedang memuat data
class PestLoading extends PestState {}

/// State saat data berhasil dimuat
class PestLoaded extends PestState {
  /// Semua data pest (tanpa filter)
  final List<Map<String, dynamic>> allPests;

  /// Data pest yang sudah difilter
  final List<Map<String, dynamic>> filteredPests;

  /// Kategori yang sedang dipilih
  final String selectedCategory;

  /// Query pencarian saat ini
  final String searchQuery;

  const PestLoaded({
    required this.allPests,
    required this.filteredPests,
    this.selectedCategory = 'Semua',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props =>
      [allPests, filteredPests, selectedCategory, searchQuery];

  PestLoaded copyWith({
    List<Map<String, dynamic>>? allPests,
    List<Map<String, dynamic>>? filteredPests,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return PestLoaded(
      allPests: allPests ?? this.allPests,
      filteredPests: filteredPests ?? this.filteredPests,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// State saat terjadi error
class PestError extends PestState {
  final String message;

  const PestError({required this.message});

  @override
  List<Object?> get props => [message];
}
