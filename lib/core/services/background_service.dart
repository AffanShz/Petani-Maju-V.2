import 'package:workmanager/workmanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:petani_maju/core/services/notification_scheduler.dart';
import 'package:petani_maju/core/services/cache_service.dart';
import 'package:petani_maju/core/services/notification_service.dart';
import 'package:petani_maju/data/datasources/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// Task names
const String weatherCheckTask = "checkWeatherCondition";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    
    if (kDebugMode) print("🔄 Background Task Started: $task");

    if (task == weatherCheckTask) {
      try {
        // Background isolate punya memori terpisah, jadi .env WAJIB di-load ulang
        // di sini sebelum service apa pun mengakses dotenv (mis. WeatherService).
        try {
          await dotenv.load(fileName: ".env");
        } catch (e) {
          if (kDebugMode) print("⚠️ Background: gagal load .env: $e");
        }

        await CacheService.init();
        await NotificationService().init();

        // Get current position directly
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final weatherService = WeatherService();
        final weatherData = await weatherService.fetchCurrentWeather(
            lat: position.latitude, lon: position.longitude);

        final scheduler = NotificationScheduler();

        // Check for alerts based on new weather data
        await scheduler.checkWeatherAlerts(weatherData);
        await scheduler.updateRainStatus(weatherData);
        await scheduler.checkPestRisk(weatherData);

        // Ensure morning briefing is scheduled for next day with latest data
        await scheduler.scheduleMorningBriefing();
      } catch (e) {
        if (kDebugMode) print("❌ Background Task Failed: $e");
        return Future.value(false);
      }
    }

    return Future.value(true);
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      // isInDebugMode removed as it is deprecated
    );

    // Register periodic task (every 1 hour)
    await Workmanager().registerPeriodicTask(
      "weather_periodic_check",
      weatherCheckTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run when connected
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    if (kDebugMode) print("✅ Background Service Initialized");
  }
}
