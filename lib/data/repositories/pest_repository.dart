import 'package:flutter/foundation.dart';
import 'package:petani_maju/data/datasources/pest_services.dart';
import 'package:petani_maju/core/services/cache_service.dart';

/// Repository untuk mengelola data Hama/Penyakit
/// Abstraksi antara BLoC dan datasource (API/Cache)
class PestRepository {
  final PestService _pestService;
  final CacheService _cacheService;

  PestRepository({
    required PestService pestService,
    required CacheService cacheService,
  })  : _pestService = pestService,
        _cacheService = cacheService;

  /// Fetch semua data pest
  /// Prioritas: Cache dulu, lalu API jika online
  Future<List<Map<String, dynamic>>> fetchPests({
    String? query,
    bool forceRefresh = false,
  }) async {
    // 1. Cek offline mode
    final offlineMode = _cacheService.getOfflineMode();

    // 2. Load dari cache dulu
    List<Map<String, dynamic>>? cachedData;
    if (!forceRefresh) {
      cachedData = _cacheService.getCachedPests();
      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint(
            'PestRepository: Loaded ${cachedData.length} pests from cache');

        // Jika offline mode, langsung return cache
        if (offlineMode) {
          return _filterByQuery(cachedData, query);
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
      final pests = await _pestService.fetchPests(query: query);

      // Save ke cache (tanpa query filter untuk menyimpan semua)
      if (query == null || query.isEmpty) {
        await _cacheService.savePestsData(pests);
      }

      debugPrint('PestRepository: Fetched ${pests.length} pests from API');
      return pests;
    } catch (e) {
      debugPrint('PestRepository: API error - $e');

      // Fallback ke cache jika API gagal
      if (cachedData != null && cachedData.isNotEmpty) {
        return _filterByQuery(cachedData, query);
      }
      rethrow;
    }
  }

  /// Fetch pest berdasarkan ID
  Future<Map<String, dynamic>?> fetchPestById(int id) async {
    // Coba dari cache dulu
    final cachedPests = _cacheService.getCachedPests();
    if (cachedPests != null) {
      try {
        return cachedPests.firstWhere((p) => p['id'] == id);
      } catch (_) {
        // Not found in cache
      }
    }

    // Fetch dari API
    if (!_cacheService.getOfflineMode()) {
      return await _pestService.fetchPestById(id);
    }

    return null;
  }

  /// Filter data berdasarkan query
  List<Map<String, dynamic>> _filterByQuery(
    List<Map<String, dynamic>> data,
    String? query,
  ) {
    if (query == null || query.isEmpty) return data;
    final lowerQuery = query.toLowerCase();
    return data.where((p) {
      final nama = (p['nama'] ?? '').toString().toLowerCase();
      return nama.contains(lowerQuery);
    }).toList();
  }
}
