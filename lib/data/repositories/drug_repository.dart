import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:petani_maju/core/services/cache_service.dart';

/// Repository untuk mengelola data Obat Tanaman
/// Abstraksi antara BLoC dan datasource (asset JSON lokal & local Hive cache)
class DrugRepository {
  final CacheService _cacheService;
  List<Map<String, dynamic>>? _cachedDrugs;

  DrugRepository({
    CacheService? cacheService,
  }) : _cacheService = cacheService ?? CacheService();

  /// Fetch semua data obat (dari memory, cache Hive, atau asset JSON)
  Future<List<Map<String, dynamic>>> fetchDrugs({
    bool forceRefresh = false,
  }) async {
    // 1. Memory cache
    if (!forceRefresh && _cachedDrugs != null) {
      return _cachedDrugs!;
    }

    // 2. Cek Hive cache jika tidak force refresh
    if (!forceRefresh) {
      final cached = _cacheService.getCachedDrugs();
      if (cached != null && cached.isNotEmpty) {
        _cachedDrugs = cached;
        debugPrint('DrugRepository: Loaded ${cached.length} drugs from Hive cache');
        return cached;
      }
    }

    // 3. Cek offline mode
    final offlineMode = _cacheService.getOfflineMode();
    if (offlineMode) {
      final cached = _cacheService.getCachedDrugs();
      if (cached != null && cached.isNotEmpty) {
        _cachedDrugs = cached;
        debugPrint('DrugRepository: Offline mode active, loaded ${cached.length} drugs from cache');
        return cached;
      }
    }

    // 4. Load dari asset katalog_obat_tanaman.json
    try {
      final jsonString =
          await rootBundle.loadString('katalog_obat_tanaman.json');
      final data = jsonDecode(jsonString) as List<dynamic>;

      final drugs = data.map((item) {
        final drug = Map<String, dynamic>.from(item as Map<String, dynamic>);
        drug['nama'] = drug['nama'] ?? drug['nama_obat'] ?? '';
        drug['kategori'] = drug['kategori'] ?? '-';
        drug['produsen'] = drug['produsen'] ?? '-';
        drug['bahan_aktif'] = drug['bahan_aktif'] ?? '-';
        drug['dosis'] = drug['dosis'] ?? '-';
        drug['deskripsi'] = drug['deskripsi'] ?? '-';
        drug['cara_pakai'] = drug['cara_pakai'] ?? '-';
        drug['sasaran'] = drug['sasaran'] ?? [];
        drug['tanaman'] = drug['tanaman'] ?? [];
        drug['organik'] = drug['kategori'] == 'Organik';
        drug['gambar_url'] = _safeString(
          drug['gambar_url'],
          fallback: _placeholderImageForCategory(drug['kategori']),
        );
        return drug;
      }).toList();

      // Simpan ke Hive cache
      await _cacheService.saveDrugsData(drugs);

      _cachedDrugs = drugs;
      debugPrint('DrugRepository: Loaded ${drugs.length} drugs from asset & saved to Hive cache');
      return drugs;
    } catch (e) {
      debugPrint('DrugRepository error: $e');
      final cached = _cacheService.getCachedDrugs();
      if (cached != null && cached.isNotEmpty) {
        _cachedDrugs = cached;
        return cached;
      }
      rethrow;
    }
  }

  String _safeString(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _placeholderImageForCategory(String category) {
    switch (category) {
      case 'Insektisida':
        return 'https://images.unsplash.com/photo-1518655048521-f130df041f66?auto=format&fit=crop&q=80&w=400';
      case 'Fungisida':
        return 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&q=80&w=400';
      case 'Bakterisida':
        return 'https://images.unsplash.com/photo-1556228720-1fae7f6a9b6b?auto=format&fit=crop&q=80&w=400';
      case 'Akarisida':
        return 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&q=80&w=400';
      case 'Organik':
        return 'https://images.unsplash.com/photo-1447175008436-054170c2e979?auto=format&fit=crop&q=80&w=400';
      default:
        return 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&q=80&w=400';
    }
  }
}
