import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get modelTomatoUrl =>
      dotenv.env['MODEL_TOMATO'] ?? 'https://wisamwr-tomato-disease-api.hf.space';

  static String get modelPlantUrl =>
      dotenv.env['MODEL_PLANT'] ??
      'https://onalla-deteksi-jenis-tanaman-api.hf.space';

  static String get modelRiceUrl =>
      dotenv.env['MODEL_RICE'] ?? 'https://aishaadr-daun-padi-api.hf.space';

  static String get modelTeaUrl =>
      dotenv.env['MODEL_TEA'] ??
      'https://nadjwasalsa-tea-leaf-disease-api.hf.space';

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get openWeatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
