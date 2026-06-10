part of 'pest_bloc.dart';

/// Events untuk PestBloc
abstract class PestEvent extends Equatable {
  const PestEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memuat data pest (saat init)
class LoadPests extends PestEvent {}

/// Event untuk refresh data (pull-to-refresh)
class RefreshPests extends PestEvent {}

/// Event untuk mencari pest berdasarkan query
class SearchPests extends PestEvent {
  final String query;

  const SearchPests({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event untuk filter berdasarkan kategori
class FilterPestsByCategory extends PestEvent {
  final String category;

  const FilterPestsByCategory({required this.category});

  @override
  List<Object?> get props => [category];
}
