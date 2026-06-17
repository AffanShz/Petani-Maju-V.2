import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:petani_maju/data/models/prediction_history.dart';
import 'package:petani_maju/data/datasources/pest_services.dart';
import 'package:petani_maju/core/services/cache_service.dart';

class HistoryRepository {
  final PestService _pestService;
  final CacheService _cacheService;

  static const String _cacheKey = 'prediction_history_cache';

  HistoryRepository({
    required PestService pestService,
    required CacheService cacheService,
  })  : _pestService = pestService,
        _cacheService = cacheService;

  /// Fetch prediction history — tries Supabase first, falls back to local cache
  Future<List<PredictionHistory>> getHistory() async {
    try {
      final raw = await _pestService.fetchPredictionHistory();
      final items = raw.map((e) => PredictionHistory.fromMap(e)).toList();

      // Save to local cache for offline use
      await _saveToCache(items);
      return items;
    } catch (e) {
      debugPrint('HistoryRepository: Supabase failed, trying cache... $e');
      return _loadFromCache();
    }
  }

  /// Delete a single history item by ID
  Future<void> deleteHistoryItem(String id) async {
    await _pestService.deletePredictionHistory(id);
    // Update local cache
    final cached = _loadFromCache();
    final updated = cached.where((item) => item.id != id).toList();
    await _saveToCache(updated);
  }

  /// Delete all history
  Future<void> deleteAllHistory() async {
    await _pestService.deleteAllPredictionHistory();
    await _saveToCache([]);
  }

  // ─── Cache helpers ──────────────────────────────────────────────────────────

  Future<void> _saveToCache(List<PredictionHistory> items) async {
    try {
      final encoded = jsonEncode(items.map((e) => e.toMap()).toList());
      await _cacheService.saveRawData(_cacheKey, encoded);
    } catch (e) {
      debugPrint('HistoryRepository: Failed to save cache: $e');
    }
  }

  List<PredictionHistory> _loadFromCache() {
    try {
      final raw = _cacheService.getRawData(_cacheKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => PredictionHistory.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      debugPrint('HistoryRepository: Cache parse error: $e');
      return [];
    }
  }
}
