import 'package:flutter/foundation.dart';
import 'package:petani_maju/data/datasources/weather_service.dart';
import 'package:petani_maju/data/datasources/location_service.dart';
import 'package:petani_maju/core/services/cache_service.dart';

/// Repository untuk mengelola data Cuaca
/// Abstraksi antara BLoC dan datasource (API/Cache)
class WeatherRepository {
  final WeatherService _weatherService;
  final LocationService _locationService;
  final CacheService _cacheService;

  WeatherRepository({
    required WeatherService weatherService,
    required LocationService locationService,
    required CacheService cacheService,
  })  : _weatherService = weatherService,
        _locationService = locationService,
        _cacheService = cacheService;

  /// Dummy data cuaca saat ini untuk fallback
  static final Map<String, dynamic> _dummyCurrentWeather = {
    'temp': 28.5,
    'feels_like': 30.2,
    'temp_min': 25.0,
    'temp_max': 31.0,
    'pressure': 1013,
    'humidity': 72,
    'weather': [
      {
        'main': 'Clouds',
        'description': 'Berawan',
        'icon': '04d',
      }
    ],
    'clouds': 60,
    'wind': {
      'speed': 3.5,
      'deg': 230,
    },
    'visibility': 9000,
    'dt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  };

  /// Dummy forecast cuaca untuk fallback
  static final List<dynamic> _dummyForecast = [
    {
      'dt': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      'temp': 28.0,
      'weather': [{'main': 'Clouds', 'description': 'Berawan'}],
      'pop': 0.0,
      'dt_txt': '2026-06-16 13:00:00'
    },
    {
      'dt': DateTime.now().add(const Duration(hours: 7)).millisecondsSinceEpoch ~/ 1000,
      'temp': 27.5,
      'weather': [{'main': 'Rain', 'description': 'Hujan ringan'}],
      'pop': 0.3,
      'dt_txt': '2026-06-16 19:00:00'
    },
    {
      'dt': DateTime.now().add(const Duration(hours: 13)).millisecondsSinceEpoch ~/ 1000,
      'temp': 25.0,
      'weather': [{'main': 'Rain', 'description': 'Hujan'}],
      'pop': 0.8,
      'dt_txt': '2026-06-17 01:00:00'
    },
    {
      'dt': DateTime.now().add(const Duration(hours: 19)).millisecondsSinceEpoch ~/ 1000,
      'temp': 24.5,
      'weather': [{'main': 'Clouds', 'description': 'Berawan'}],
      'pop': 0.2,
      'dt_txt': '2026-06-17 07:00:00'
    },
  ];

  /// Fetch cuaca saat ini
  /// Fallback: cache → dummy data lokal
  Future<Map<String, dynamic>> fetchCurrentWeather({
    double? lat,
    double? lon,
  }) async {
    // Cek offline mode
    final offlineMode = _cacheService.getOfflineMode();

    // Load dari cache dulu
    final cachedWeather = _cacheService.getCachedCurrentWeather();
    if (cachedWeather != null) {
      debugPrint('WeatherRepository: Loaded weather from cache');

      if (offlineMode) {
        return cachedWeather;
      }
    }

    // Fetch dari API
    try {
      final weather =
          await _weatherService.fetchCurrentWeather(lat: lat, lon: lon);
      return weather;
    } catch (e) {
      debugPrint('WeatherRepository: API error - $e');

      // Fallback ke cache jika API gagal
      if (cachedWeather != null) {
        return cachedWeather;
      }

      // Fallback terakhir: gunakan dummy data lokal
      debugPrint('WeatherRepository: Using dummy weather data as fallback');
      return _dummyCurrentWeather;
    }
  }

  /// Fetch forecast cuaca
  /// Fallback: cache → dummy data lokal
  Future<List<dynamic>> fetchForecast({
    double? lat,
    double? lon,
  }) async {
    // Cek offline mode
    final offlineMode = _cacheService.getOfflineMode();

    // Load dari cache dulu
    final cachedForecast = _cacheService.getCachedForecast();
    if (cachedForecast != null) {
      debugPrint('WeatherRepository: Loaded forecast from cache');

      if (offlineMode) {
        return cachedForecast;
      }
    }

    // Fetch dari API
    try {
      final forecast = await _weatherService.fetchForecast(lat: lat, lon: lon);
      return forecast['list'] ?? [];
    } catch (e) {
      debugPrint('WeatherRepository: API error - $e');

      // Fallback ke cache jika API gagal
      if (cachedForecast != null) {
        return cachedForecast;
      }

      // Fallback terakhir: gunakan dummy forecast lokal
      debugPrint('WeatherRepository: Using dummy forecast data as fallback');
      return _dummyForecast;
    }
  }

  /// Fetch lokasi detail
  Future<String?> fetchDetailedLocation(double lat, double lon) async {
    try {
      final locationData = await _locationService.getDetailedLocation(lat, lon);
      final locationStr = locationData['full'];

      // Save ke cache
      if (locationStr != null && locationStr.isNotEmpty) {
        await _cacheService.saveLocationData(locationStr, lat, lon);
      }

      return locationStr;
    } catch (e) {
      debugPrint('WeatherRepository: Location error - $e');
      // Fallback ke cached location atau dummy
      return _cacheService.getCachedDetailedLocation() ?? 'Jakarta, Indonesia';
    }
  }

  /// Simpan data cuaca ke cache
  Future<void> saveWeatherToCache({
    required Map<String, dynamic> currentWeather,
    required List<dynamic> forecastList,
  }) async {
    await _cacheService.saveWeatherData(
      currentWeather: currentWeather,
      forecastList: forecastList,
    );
  }

  /// Get cached location
  String? getCachedLocation() {
    return _cacheService.getCachedDetailedLocation();
  }

  /// Get cache time
  DateTime? getCacheTime() {
    return _cacheService.getWeatherCacheTime();
  }
}
