part of 'home_bloc.dart';

/// States untuk Home BLoC
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum data dimuat
class HomeInitial extends HomeState {}

/// State saat sedang memuat data
class HomeLoading extends HomeState {
  /// Apakah ini loading dari cache (true) atau full loading (false)
  final bool isRefreshing;

  const HomeLoading({this.isRefreshing = false});

  @override
  List<Object?> get props => [isRefreshing];
}

/// State saat data berhasil dimuat
class HomeLoaded extends HomeState {
  /// Data cuaca saat ini dari API
  final Map<String, dynamic> currentWeather;

  /// List data forecast cuaca
  final List<dynamic> forecastList;

  /// Lokasi detail (alamat lengkap)
  final String? detailedLocation;

  /// Waktu terakhir data disinkronkan
  final DateTime? lastSyncTime;

  /// Apakah saat ini online atau menggunakan cache
  final bool isOnline;

  /// Pesan alert/rekomendasi tanaman berdasarkan cuaca
  final String? alertMessage;

  const HomeLoaded({
    required this.currentWeather,
    required this.forecastList,
    this.detailedLocation,
    this.lastSyncTime,
    this.isOnline = true,
    this.alertMessage,
  });

  @override
  List<Object?> get props => [
        currentWeather,
        forecastList,
        detailedLocation,
        lastSyncTime,
        isOnline,
        alertMessage,
      ];

  /// Copy with method untuk update partial state
  HomeLoaded copyWith({
    Map<String, dynamic>? currentWeather,
    List<dynamic>? forecastList,
    String? detailedLocation,
    DateTime? lastSyncTime,
    bool? isOnline,
    String? alertMessage,
  }) {
    return HomeLoaded(
      currentWeather: currentWeather ?? this.currentWeather,
      forecastList: forecastList ?? this.forecastList,
      detailedLocation: detailedLocation ?? this.detailedLocation,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isOnline: isOnline ?? this.isOnline,
      alertMessage: alertMessage ?? this.alertMessage,
    );
  }
}

/// State saat terjadi error
class HomeError extends HomeState {
  /// Pesan error untuk ditampilkan ke user
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}
