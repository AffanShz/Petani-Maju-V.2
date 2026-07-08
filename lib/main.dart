import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core Services
import 'package:petani_maju/core/services/cache_service.dart';
import 'package:petani_maju/core/services/notification_service.dart';

import 'package:petani_maju/core/services/background_service.dart';
import 'package:petani_maju/core/services/connectivity_service.dart';

// Datasources
import 'package:petani_maju/data/datasources/weather_service.dart';
import 'package:petani_maju/data/datasources/location_service.dart';
import 'package:petani_maju/data/datasources/pest_services.dart';
import 'package:petani_maju/data/datasources/tips_services.dart';
import 'package:petani_maju/data/datasources/planting_schedule_service.dart';
import 'package:petani_maju/data/datasources/chatbot_service.dart';
import 'package:petani_maju/data/repositories/chatbot_repository.dart';
import 'package:petani_maju/core/constants/env_config.dart';

// Repositories
import 'package:petani_maju/data/repositories/weather_repository.dart';
import 'package:petani_maju/data/repositories/pest_repository.dart';
import 'package:petani_maju/data/repositories/tips_repository.dart';
import 'package:petani_maju/data/repositories/calendar_repository.dart';
import 'package:petani_maju/data/repositories/history_repository.dart';
import 'package:petani_maju/data/repositories/drug_repository.dart';

// Global BLoC
import 'package:petani_maju/logic/app_lifecycle/app_bloc.dart';

// UI
import 'package:petani_maju/features/onboarding/screens/onboarding_screen.dart';
import 'package:petani_maju/widgets/navbaar.dart';

bool appStartedOffline = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  await CacheService.init();
  await NotificationService().init();

  // Inisialisasi Background Service (hanya untuk mobile platforms)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await BackgroundService().init();
  }
  // ConnectivityService di-init secara async agar tidak blocking startup
  ConnectivityService().init();

  await initializeDateFormatting('id_ID', null);

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    ).timeout(const Duration(seconds: 10));
    appStartedOffline = false;
  } on TimeoutException {
    debugPrint('Supabase initialization timeout - continuing offline');
    appStartedOffline = true;
    CacheService().setOfflineMode(true);
  } catch (e) {
    debugPrint('Supabase initialization error: $e - continuing offline');
    appStartedOffline = true;
    CacheService().setOfflineMode(true);
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('id'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('id'),
      startLocale: const Locale('id'),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cacheService = CacheService();
    final weatherService = WeatherService();
    final locationService = LocationService();
    final pestService = PestService();
    final tipsService = TipsService();
    final scheduleService = PlantingScheduleService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WeatherRepository>(
          create: (_) => WeatherRepository(
            weatherService: weatherService,
            locationService: locationService,
            cacheService: cacheService,
          ),
        ),
        RepositoryProvider<PestRepository>(
          create: (_) => PestRepository(
            pestService: pestService,
            cacheService: cacheService,
          ),
        ),
        RepositoryProvider<TipsRepository>(
          create: (_) => TipsRepository(
            tipsService: tipsService,
            cacheService: cacheService,
          ),
        ),
        RepositoryProvider<CalendarRepository>(
          create: (_) => CalendarRepository(
            scheduleService: scheduleService,
          ),
        ),
        RepositoryProvider<HistoryRepository>(
          create: (_) => HistoryRepository(
            pestService: pestService,
            cacheService: cacheService,
          ),
        ),
        RepositoryProvider<DrugRepository>(
          create: (_) => DrugRepository(),
        ),
        RepositoryProvider<ChatbotRepository>(
          create: (_) => ChatbotRepository(
            chatbotService: ChatbotService(
              apiKey: EnvConfig.geminiApiKey,
            ),
            cacheService: cacheService,
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>(
            create: (context) => AppBloc(
              cacheService: cacheService,
            )..add(AppStarted()),
          ),
        ],
        child: MaterialApp(
          title: 'Petani Maju',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            useMaterial3: true,
          ),
          home: BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              if (state is AppLoading) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is AppOnboarding) {
                return const OnboardingScreen();
              }

              return BlocListener<AppBloc, AppState>(
                listener: (context, state) {
                  if (state is AppReady && !state.isConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.wifi_off, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tidak ada koneksi internet. Menggunakan data tersimpan.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange.shade700,
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const MainScreen(),
              );
            },
          ),
        ),
      ),
    );
  }
}
