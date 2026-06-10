part of 'tips_bloc.dart';

/// States untuk TipsBloc
abstract class TipsState extends Equatable {
  const TipsState();

  @override
  List<Object?> get props => [];
}

/// State awal
class TipsInitial extends TipsState {}

/// State saat sedang memuat data
class TipsLoading extends TipsState {}

/// State saat data berhasil dimuat
class TipsLoaded extends TipsState {
  final List<Map<String, dynamic>> tips;
  final List<Map<String, dynamic>> filteredTips;
  final String searchQuery;
  final String selectedCategory;

  const TipsLoaded({
    required this.tips,
    this.filteredTips = const [],
    this.searchQuery = '',
    this.selectedCategory = 'Semua',
  });

  @override
  List<Object?> get props =>
      [tips, filteredTips, searchQuery, selectedCategory];

  TipsLoaded copyWith({
    List<Map<String, dynamic>>? tips,
    List<Map<String, dynamic>>? filteredTips,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return TipsLoaded(
      tips: tips ?? this.tips,
      filteredTips: filteredTips ?? this.filteredTips,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

/// State saat terjadi error
class TipsError extends TipsState {
  final String message;

  const TipsError({required this.message});

  @override
  List<Object?> get props => [message];
}
