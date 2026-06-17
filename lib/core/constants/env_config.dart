import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get modelTomatoUrl =>
      dotenv.env['MODEL_TOMATO'] ?? 'https://wisamwr-tomato-disease-api.hf.space';

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get openWeatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
