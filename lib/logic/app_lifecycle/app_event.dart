part of 'app_bloc.dart';

/// Events untuk AppBloc (Global Application State)
abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat aplikasi pertama kali dimulai
class AppStarted extends AppEvent {}

/// Event saat status koneksi berubah
class ConnectivityChanged extends AppEvent {
  final bool isConnected;

  const ConnectivityChanged({required this.isConnected});

  @override
  List<Object?> get props => [isConnected];
}

/// Event untuk toggle offline mode manual
class ToggleOfflineMode extends AppEvent {
  final bool offlineMode;

  const ToggleOfflineMode({required this.offlineMode});

  @override
  List<Object?> get props => [offlineMode];
}

class CompleteOnboarding extends AppEvent {}
