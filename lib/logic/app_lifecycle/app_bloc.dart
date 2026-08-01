import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    on<AppLoggedIn>(_onAppLoggedIn);
    on<AppLoggedOut>(_onAppLoggedOut);
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

      // Check initial connectivity & offline pref dari cache.
      // offlineMode = preferensi manual user; isConnected = status sistem
      // (ditulis oleh ConnectivityService / startup).
      final offlineModeEnabled = _cacheService.getUserPrefOfflineMode();
      final isConnected = _cacheService.isConnected();

      // Check for first time launch for Onboarding
      if (_cacheService.isFirstTime()) {
        emit(AppOnboarding());
        return;
      }

      // Check if user is already authenticated (safely handle uninitialized Supabase)
      User? currentUser;
      try {
        currentUser = Supabase.instance.client.auth.currentUser;
      } catch (e) {
        debugPrint('AppBloc: Supabase not initialized or offline ($e)');
      }

      if (currentUser != null) {
        emit(AppReady(
          isConnected: isConnected,
          offlineModeEnabled: offlineModeEnabled,
        ));
        debugPrint(
            'AppBloc: App ready. Connected: $isConnected, Offline mode: $offlineModeEnabled');
      } else {
        emit(AppLogin());
        debugPrint('AppBloc: No authenticated user, showing login screen.');
      }
    } catch (e) {
      debugPrint('AppBloc Error: $e');
      emit(AppError(message: e.toString()));
    }
  }

  /// Handle perubahan status koneksi
  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<AppState> emit,
  ) async {
    await _cacheService.setConnected(event.isConnected);

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
    emit(AppLogin());
    debugPrint('AppBloc: Onboarding complete, showing login screen.');
  }

  /// Handle user successfully logged in
  Future<void> _onAppLoggedIn(
    AppLoggedIn event,
    Emitter<AppState> emit,
  ) async {
    final offlineModeEnabled = _cacheService.getUserPrefOfflineMode();
    final isConnected = _cacheService.isConnected();

    emit(AppReady(
      isConnected: isConnected,
      offlineModeEnabled: offlineModeEnabled,
    ));
    debugPrint('AppBloc: User logged in, app ready.');
  }

  /// Handle user logout
  FutureOr<void> _onAppLoggedOut(
    AppLoggedOut event,
    Emitter<AppState> emit,
  ) {
    emit(AppLogin());
    debugPrint('AppBloc: User logged out, showing login screen.');
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
