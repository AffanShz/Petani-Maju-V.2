import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:petani_maju/core/services/cache_service.dart';
import 'package:petani_maju/core/services/connectivity_service.dart';

part 'app_event.dart';
part 'app_state.dart';

/// Global BLoC untuk mengelola state aplikasi secara keseluruhan
/// Termasuk: inisialisasi, monitoring koneksi, dan offline mode
class AppBloc extends Bloc<AppEvent, AppState> {
  final CacheService _cacheService;
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;

  AppBloc({
    required CacheService cacheService,
  })  : _cacheService = cacheService,
        super(AppInitial()) {
    on<AppStarted>(_onAppStarted);
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<ToggleOfflineMode>(_onToggleOfflineMode);
    on<CompleteOnboarding>(_onCompleteOnboarding);
  }

  /// Handle aplikasi pertama kali dimulai
  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AppState> emit,
  ) async {
    emit(AppLoading());

    try {
      // Listen to connectivity changes via ConnectivityService
      // ConnectivityService broadcasts 'isOffline' (bool)
      _connectivitySubscription =
          _connectivityService.offlineStatusStream.listen((isOffline) {
        add(ConnectivityChanged(isConnected: !isOffline));
      });

      // Check initial connectivity from CacheService (set by ConnectivityService.init)
      final offlineModeEnabled = _cacheService.getOfflineMode();
      // Since ConnectivityService.init run before this, getOfflineMode reflects actual connectivity status initially
      // But we generally separate "System Connectivity" (isConnected) from "User Preference" (offlineModeEnabled)
      // For now, let's assume if CacheService says we are offline, we are offline unless user toggled it?
      // Actually, CacheService stores the user preference for offline mode in 'offlineMode'.
      // Wait, ConnectivityService.init updates 'offlineMode' in cache automatically?
      // Yes: _cacheService.setOfflineMode(isOffline); in ConnectivityService.dart

      // So getOfflineMode() returns the actual connectivity status or the user forced blocking?
      // Looking at ConnectivityService: it calls setOfflineMode(isOffline).
      // So 'offlineMode' in cache effectively tracks "is the app currently offline due to net or user?".
      // But AppBloc separates isConnected vs offlineModeEnabled.

      // Let's rely on ConnectivityService for 'isConnected'.
      // Effectively, we can just assume we are connected initially if we want,
      // or we trust that the stream will emit immediately if we listen? Streams don't emit current value on listen usually unless BehaviourSubject.

      // Since we don't want to await checkConnectivity again, let's assume true and let the stream correct us,
      // OR better, checking CacheService is safe.
      final isConnected = !_cacheService
          .getOfflineMode(); // Use the cache as a proxy for initial state

      // Check for first time launch for Onboarding
      if (_cacheService.isFirstTime()) {
        emit(AppOnboarding());
        return;
      }

      emit(AppReady(
        isConnected: isConnected,
        offlineModeEnabled: offlineModeEnabled,
      ));

      debugPrint(
          'AppBloc: App ready. Connected: $isConnected, Offline mode: $offlineModeEnabled');
    } catch (e) {
      debugPrint('AppBloc Error: $e');
      emit(const AppReady(isConnected: true, offlineModeEnabled: false));
    }
  }

  /// Handle perubahan status koneksi
  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<AppState> emit,
  ) {
    final currentState = state;
    if (currentState is AppReady) {
      emit(currentState.copyWith(isConnected: event.isConnected));
      debugPrint('AppBloc: Connectivity changed to ${event.isConnected}');
    }
  }

  /// Handle toggle offline mode manual
  Future<void> _onToggleOfflineMode(
    ToggleOfflineMode event,
    Emitter<AppState> emit,
  ) async {
    final currentState = state;
    if (currentState is AppReady) {
      // Save preference
      await _cacheService.setOfflineMode(event.offlineMode);
      emit(currentState.copyWith(offlineModeEnabled: event.offlineMode));
      debugPrint('AppBloc: Offline mode set to ${event.offlineMode}');
    }
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<AppState> emit,
  ) async {
    await _cacheService.setFirstTime(false);

    // We can re-check connectivity or use existing state logic
    final offlineModeEnabled = _cacheService.getOfflineMode();
    final isConnected = !offlineModeEnabled;

    emit(AppReady(
      isConnected: isConnected,
      offlineModeEnabled: offlineModeEnabled,
    ));
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
