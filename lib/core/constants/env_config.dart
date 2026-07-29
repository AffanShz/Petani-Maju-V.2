import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String _getEnv(String key, String dartDefineVal,
      {String defaultValue = ''}) {
    if (dartDefineVal.isNotEmpty) {
      return dartDefineVal;
    }
    if (dotenv.isInitialized) {
      return dotenv.env[key] ?? defaultValue;
    }
    return defaultValue;
  }

  static String get modelTomatoUrl =>
      _getEnv('MODEL_TOMATO', const String.fromEnvironment('MODEL_TOMATO'));
  static String get modelPlantUrl =>
      _getEnv('MODEL_PLANT', const String.fromEnvironment('MODEL_PLANT'));
  static String get modelRiceUrl =>
      _getEnv('MODEL_RICE', const String.fromEnvironment('MODEL_RICE'));
  static String get modelTeaUrl =>
      _getEnv('MODEL_TEA', const String.fromEnvironment('MODEL_TEA'));

  static String get supabaseUrl =>
      _getEnv('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL'));
  static String get supabaseAnonKey => _getEnv(
      'SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY'));

  static String get openWeatherApiKey => _getEnv('OPENWEATHER_API_KEY',
      const String.fromEnvironment('OPENWEATHER_API_KEY'));
  static String get geminiApiKey =>
      _getEnv('GEMINI_API_KEY', const String.fromEnvironment('GEMINI_API_KEY'));

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
