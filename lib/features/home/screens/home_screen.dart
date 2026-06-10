import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:petani_maju/features/home/bloc/home_bloc.dart';
import 'package:petani_maju/features/home/widgets/forecast_list.dart';
import 'package:petani_maju/features/home/widgets/quick_access.dart';
import 'package:petani_maju/features/home/widgets/tips_list.dart';
import 'package:petani_maju/features/home/widgets/weather_alert.dart';
import 'package:petani_maju/widgets/custom_app_bar.dart';
import 'package:petani_maju/widgets/main_weather_card.dart';
import 'package:petani_maju/widgets/section_header.dart';
import 'package:petani_maju/features/weather/screens/weather_detail_screen.dart';
import 'package:petani_maju/core/services/notification_service.dart';
import 'package:petani_maju/features/home/widgets/home_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Flag untuk mencegah notifikasi muncul berulang kali
  bool _hasShownNotification = false;

  @override
  void initState() {
    super.initState();
    // Request notification permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService().requestPermissions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            // Handle side effects: notifications dan snackbar
            if (state is HomeLoaded && state.alertMessage != null) {
              // Tampilkan notifikasi hanya sekali
              if (!_hasShownNotification) {
                NotificationService().showNotification(
                  id: 101,
                  title: 'Info Tanaman',
                  body: state.alertMessage!,
                );
                _hasShownNotification = true;
              }
            }

            // Tampilkan snackbar saat error
            if (state is HomeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            // Tampilkan snackbar saat offline
            if (state is HomeLoaded && !state.isOnline) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Menampilkan data dari cache'),
                    ],
                  ),
                  backgroundColor: Colors.orange.shade700,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            // State: Initial atau Loading (tanpa data sebelumnya)
            if (state is HomeInitial ||
                (state is HomeLoading && !state.isRefreshing)) {
              return const HomeSkeleton();
            }

            // State: Error (tanpa data fallback)
            if (state is HomeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.signal_wifi_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<HomeBloc>().add(LoadHomeData());
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // State: Loaded (dengan data)
            if (state is HomeLoaded) {
              return _buildContent(context, state);
            }

            // State: Loading saat refresh (sudah ada data sebelumnya)
            if (state is HomeLoading && state.isRefreshing) {
              // Ambil state sebelumnya jika ada
              return const HomeSkeleton();
            }

            // Fallback
            return const HomeSkeleton();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(RefreshHomeData());
          // Tunggu state berubah dari loading
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              CustomAppBar(
                lastSyncTime: state.lastSyncTime,
                isOnline: state.isOnline,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeatherDetailScreen(),
                    ),
                  );
                },
                child: MainWeatherCard(
                  weatherData: state.currentWeather,
                  detailedLocation: state.detailedLocation,
                  onRefresh: () {
                    context.read<HomeBloc>().add(RefreshHomeData());
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Widget Alert (Rekomendasi Tanaman)
              if (state.alertMessage != null) ...[
                WeatherAlert(message: state.alertMessage!),
                const SizedBox(height: 20),
              ],

              SectionHeader(
                title: 'home.weather_label'.tr(),
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeatherDetailScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ForecastList(forecastData: state.forecastList),

              const SizedBox(height: 20),

              SectionHeader(
                title: 'home.menu_tips'.tr(),
                onActionTap: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(2); // Switch to Tips tab (index 2)
                  }
                },
              ),
              const SizedBox(height: 16),
              const TipsList(),
              const SizedBox(height: 20),
              const QuickAccess(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
