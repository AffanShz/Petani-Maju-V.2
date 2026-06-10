import 'package:flutter/foundation.dart';
import 'package:petani_maju/data/datasources/tips_services.dart';
import 'package:petani_maju/core/services/cache_service.dart';

/// Repository untuk mengelola data Tips Pertanian
/// Abstraksi antara BLoC dan datasource (API/Cache)
class TipsRepository {
  final TipsService _tipsService;
  final CacheService _cacheService;

  TipsRepository({
    required TipsService tipsService,
    required CacheService cacheService,
  })  : _tipsService = tipsService,
        _cacheService = cacheService;

  /// Fetch semua tips
  /// Prioritas: Cache dulu, lalu API jika online
  Future<List<Map<String, dynamic>>> fetchTips({
    bool forceRefresh = false,
  }) async {
    // 1. Cek offline mode
    final offlineMode = _cacheService.getOfflineMode();

    // 2. Load dari cache dulu
    List<Map<String, dynamic>>? cachedData;
    if (!forceRefresh) {
      cachedData = _cacheService.getCachedTips();
      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint(
            'TipsRepository: Loaded ${cachedData.length} tips from cache');

        // Jika offline mode, langsung return cache
        if (offlineMode) {
          return cachedData;
        }
      }
    }

    // 3. Jika offline mode aktif dan tidak ada cache, throw error
    if (offlineMode && (cachedData == null || cachedData.isEmpty)) {
      throw Exception(
          'Tidak ada data tersimpan. Silakan hubungkan ke internet.');
    }

    // 4. Fetch dari API
    try {
      final tips = await _tipsService.fetchTips();

      // Save ke cache
      await _cacheService.saveTipsData(tips);

      debugPrint('TipsRepository: Fetched ${tips.length} tips from API');
      return tips;
    } catch (e) {
      debugPrint('TipsRepository: API error - $e');

      // Fallback ke cache jika API gagal
      if (cachedData != null && cachedData.isNotEmpty) {
        return cachedData;
      }
      rethrow;
    }
  }
}
