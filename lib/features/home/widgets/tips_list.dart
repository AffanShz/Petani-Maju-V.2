import 'package:flutter/material.dart';
import 'package:petani_maju/features/home/widgets/tip_item.dart';
import 'package:petani_maju/data/datasources/tips_services.dart';
import 'package:petani_maju/core/services/cache_service.dart';

class TipsList extends StatefulWidget {
  const TipsList({super.key});

  @override
  State<TipsList> createState() => _TipsListState();
}

class _TipsListState extends State<TipsList> {
  final TipsService _tipsService = TipsService();
  final CacheService _cacheService = CacheService();

  List<Map<String, dynamic>> _tips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer to after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTips();
    });
  }

  Future<void> _loadTips() async {
    // 1. Load from cache first
    final cachedTips = _cacheService.getCachedTips();
    if (cachedTips != null && cachedTips.isNotEmpty) {
      if (mounted) {
        setState(() {
          _tips = cachedTips;
          _isLoading = false;
        });
      }
    }

    // 2. Check if offline mode is enabled
    final offlineMode = _cacheService.getOfflineMode();
    if (offlineMode) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // 3. Fetch from API (online mode)
    try {
      final freshTips = await _tipsService.fetchTips();

      // Save to cache
      await _cacheService.saveTipsData(freshTips);

      if (mounted) {
        setState(() {
          _tips = freshTips;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      // Only show error if we don't have cached data
      if (_tips.isEmpty) {
        if (mounted) {
          setState(() {
            _error = "Gagal memuat tips: $e";
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Tinggi kartu ikut skala font sistem.
  ///
  /// Gambar di dalam kartu tingginya tetap, tapi kategori dan judulnya ikut
  /// membesar saat user memperbesar ukuran teks di setelan HP. Tinggi mati
  /// 190 membuat teks itu meluber ke bawah, jadi tambahkan ruang sebanding
  /// dengan kenaikan skalanya.
  double _cardHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return 190 + (scale - 1).clamp(0.0, 0.8) * 80;
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = _cardHeight(context);

    if (_isLoading && _tips.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _tips.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: Center(child: Text(_error!)),
      );
    }

    if (_tips.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: const Center(child: Text("Belum ada tips tersedia")),
      );
    }

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _tips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tip = _tips[index];
          return TipItem(
            image: tip['image_url'] ?? 'https://via.placeholder.com/300',
            category: tip['category'] ?? 'Umum',
            title: tip['title'] ?? 'Tanpa Judul',
            tipData: tip,
          );
        },
      ),
    );
  }
}
