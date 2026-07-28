import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String _getEnv(String key, {String defaultValue = ''}) {
    const fromEnv = String.fromEnvironment;
    final value = fromEnv(key);
    if (value.isNotEmpty) {
      return value;
    }
    return dotenv.env[key] ?? defaultValue;
  }

  static String get modelTomatoUrl => _getEnv('MODEL_TOMATO');
  static String get modelPlantUrl => _getEnv('MODEL_PLANT');
  static String get modelRiceUrl => _getEnv('MODEL_RICE');
  static String get modelTeaUrl => _getEnv('MODEL_TEA');

  static String get supabaseUrl => _getEnv('SUPABASE_URL');
  static String get supabaseAnonKey => _getEnv('SUPABASE_ANON_KEY');

  static String get openWeatherApiKey => _getEnv('OPENWEATHER_API_KEY');
  static String get geminiApiKey => _getEnv('GEMINI_API_KEY');

  /// Assert or validate that all base URLs use HTTPS for security
  static bool validateHttpsUrls() {
    final urls = [
      modelTomatoUrl,
      modelPlantUrl,
      modelRiceUrl,
      modelTeaUrl,
      supabaseUrl,
    ];
    for (final url in urls) {
      if (url.isNotEmpty && !url.startsWith('https://')) {
        return false;
      }
    }
    return true;
  }
}
