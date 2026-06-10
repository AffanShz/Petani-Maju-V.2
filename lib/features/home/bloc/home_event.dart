part of 'home_bloc.dart';

/// Events untuk Home BLoC
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// Event dipanggil saat aplikasi pertama kali dimulai (init)
class LoadHomeData extends HomeEvent {}

/// Event dipanggil saat user melakukan pull-to-refresh
class RefreshHomeData extends HomeEvent {}
