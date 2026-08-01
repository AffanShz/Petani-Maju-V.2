import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petani_maju/core/constants/env_config.dart';

class WeatherService {
  String get apiKey => EnvConfig.openWeatherApiKey;

  final double lat = -6.5716;
  final double lon = 107.7587;

  // Timeout duration for all requests
  static const Duration _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> fetchCurrentWeather(
      {double? lat, double? lon}) async {
    final latitude = lat ?? this.lat;
    final longitude = lon ?? this.lon;

    if (apiKey.isEmpty) {
      throw Exception('API Key not configured. Build with --dart-define-from-file=secrets.json');
    }

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric&lang=id');
    final response = await http.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load current weather');
    }
  }

  Future<Map<String, dynamic>> fetchForecast({double? lat, double? lon}) async {
    final latitude = lat ?? this.lat;
    final longitude = lon ?? this.lon;

    if (apiKey.isEmpty) {
      throw Exception('API Key not configured. Build with --dart-define-from-file=secrets.json');
    }

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric&lang=id');
    final response = await http.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load forecast');
    }
  }
}
