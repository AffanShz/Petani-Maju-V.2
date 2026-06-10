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

  /// Fetch cuaca saat ini
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

    // Jika offline mode dan tidak ada cache
    if (offlineMode && cachedWeather == null) {
      throw Exception('Tidak ada data cuaca tersimpan.');
    }

    // Fetch dari API
    try {
      final weather =
          await _weatherService.fetchCurrentWeather(lat: lat, lon: lon);
      return weather;
    } catch (e) {
      debugPrint('WeatherRepository: API error - $e');
      if (cachedWeather != null) {
        return cachedWeather;
      }
      rethrow;
    }
  }

  /// Fetch forecast cuaca
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

    // Jika offline mode dan tidak ada cache
    if (offlineMode && cachedForecast == null) {
      throw Exception('Tidak ada data forecast tersimpan.');
    }

    // Fetch dari API
    try {
      final forecast = await _weatherService.fetchForecast(lat: lat, lon: lon);
      return forecast['list'] ?? [];
    } catch (e) {
      debugPrint('WeatherRepository: API error - $e');
      if (cachedForecast != null) {
        return cachedForecast;
      }
      rethrow;
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
      return _cacheService.getCachedDetailedLocation();
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
