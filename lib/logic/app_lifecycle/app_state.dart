part of 'app_bloc.dart';

/// States untuk AppBloc (Global Application State)
abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum inisialisasi
class AppInitial extends AppState {}

/// State saat aplikasi sedang inisialisasi
class AppLoading extends AppState {}

class AppOnboarding extends AppState {}

/// State saat aplikasi siap digunakan
class AppReady extends AppState {
  /// Apakah saat ini terhubung ke internet
  final bool isConnected;

  /// Apakah offline mode diaktifkan secara manual oleh user
  final bool offlineModeEnabled;

  const AppReady({
    required this.isConnected,
    this.offlineModeEnabled = false,
  });

  @override
  List<Object?> get props => [isConnected, offlineModeEnabled];

  /// Cek apakah aplikasi harus beroperasi dalam mode offline
  /// (baik karena tidak ada koneksi atau user mengaktifkan manual)
  bool get isOffline => !isConnected || offlineModeEnabled;

  AppReady copyWith({
    bool? isConnected,
    bool? offlineModeEnabled,
  }) {
    return AppReady(
      isConnected: isConnected ?? this.isConnected,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
    );
  }
}

/// State saat terjadi error fatal pada inisialisasi
class AppError extends AppState {
  final String message;

  const AppError({required this.message});

  @override
  List<Object?> get props => [message];
}
