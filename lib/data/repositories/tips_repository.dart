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

  /// Dummy data tips lokal untuk fallback
  static final List<Map<String, dynamic>> _dummyTips = [
    {
      'id': 1,
      'judul': 'Cara Menanam Padi yang Benar',
      'kategori': 'Padi',
      'konten':
          'Padi adalah tanaman pangan utama. Berikut langkah menanam padi:\n1. Persiapan lahan selama 2 minggu\n2. Penyemaian benih berkualitas\n3. Penanaman dengan jarak 25x25cm\n4. Pemeliharaan rutin selama pertumbuhan\n5. Panen saat padi sudah masak kuning',
      'gambar_url':
          'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&q=80&w=500',
      'tips_ekstra': 'Gunakan benih yang telah disertifikasi untuk hasil optimal.'
    },
    {
      'id': 2,
      'judul': 'Budidaya Jagung untuk Pemula',
      'kategori': 'Jagung',
      'konten':
          'Jagung adalah komoditas bernilai tinggi. Tips budidaya jagung:\n1. Pilih varietas yang sesuai iklim\n2. Olah tanah hingga subur\n3. Tanam dengan jarak 75x25cm\n4. Berikan pupuk NPK saat berumur 3 minggu\n5. Rawat hingga panen (±4 bulan)',
      'gambar_url':
          'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&q=80&w=500',
      'tips_ekstra': 'Jagung membutuhkan sinar matahari penuh untuk pertumbuhan optimal.'
    },
    {
      'id': 3,
      'judul': 'Nutrisi Tanaman & Pemupukan Tepat',
      'kategori': 'Nutrisi Tanaman',
      'konten':
          'Pemupukan yang tepat meningkatkan hasil panen hingga 40%.\nMacam nutrisi utama:\n- N (Nitrogen): untuk pertumbuhan daun dan batang\n- P (Fosfor): untuk pembentukan akar dan buah\n- K (Kalium): untuk ketahanan tanaman\nBerikan pupuk sesuai kebutuhan tanaman di setiap fase pertumbuhan.',
      'gambar_url':
          'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&q=80&w=500',
      'tips_ekstra':
          'Gunakan pupuk organik sebagai dasar, tambah pupuk kimia sesuai kebutuhan.'
    },
    {
      'id': 4,
      'judul': 'Pencegahan & Pengendalian Hama Tanaman',
      'kategori': 'Hama & Penyakit',
      'konten':
          'Hama dapat merusak hasil panen hingga 50%. Cara pencegahan:\n1. Gunakan bibit sehat\n2. Lakukan rotasi tanaman\n3. Pantau kehadiran hama secara berkala\n4. Gunakan pestisida nabati sebagai alternatif ramah lingkungan\n5. Aplikasi pestisida kimia jika diperlukan',
      'gambar_url':
          'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&q=80&w=500',
      'tips_ekstra':
          'Panen hama secara manual pada tahap awal lebih efektif dan aman.'
    },
    {
      'id': 5,
      'judul': 'Manajemen Irigasi di Musim Kering',
      'kategori': 'Teknik Pertanian',
      'konten':
          'Irigasi yang tepat sangat penting saat musim kering:\n1. Siram pada pagi atau sore hari untuk meminimalkan penguapan\n2. Berikan air secara konsisten, jangan hingga kering total\n3. Gunakan mulsa untuk menjaga kelembaban tanah\n4. Manfaatkan teknologi tetes (drip irrigation) jika memungkinkan',
      'gambar_url':
          'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&q=80&w=500',
      'tips_ekstra':
          'Monitor curah hujan dan sesuaikan jadwal irigasi untuk efisiensi air.'
    },
  ];

  /// Fetch semua tips
  /// Prioritas: Cache dulu, lalu API jika online, terakhir dummy data
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

    // 3. Fetch dari API
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

      // Fallback terakhir: gunakan dummy data lokal
      debugPrint(
          'TipsRepository: Using ${_dummyTips.length} dummy tips as fallback');
      return _dummyTips;
    }
  }
}
