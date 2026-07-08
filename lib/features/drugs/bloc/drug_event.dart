part of 'drug_bloc.dart';

/// Events untuk DrugBloc
abstract class DrugEvent extends Equatable {
  const DrugEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memuat data obat (saat init)
class LoadDrugs extends DrugEvent {}

/// Event untuk refresh data (pull-to-refresh)
class RefreshDrugs extends DrugEvent {}

/// Event untuk mencari obat berdasarkan query
class SearchDrugs extends DrugEvent {
  final String query;

  const SearchDrugs({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event untuk filter berdasarkan kategori
class FilterDrugsByCategory extends DrugEvent {
  final String category;

  const FilterDrugsByCategory({required this.category});

  @override
  List<Object?> get props => [category];
}
