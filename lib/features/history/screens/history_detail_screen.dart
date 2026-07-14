import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petani_maju/core/constants/colors.dart';
import '../../../data/models/prediction_history.dart';
import '../../../data/datasources/pest_services.dart';
import '../../drugs/screens/drug_detail_screen.dart';

class HistoryDetailScreen extends StatefulWidget {
  final PredictionHistory item;

  const HistoryDetailScreen({super.key, required this.item});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final PestService _pestService = PestService();

  Map<String, dynamic>? _pestData;
  List<Map<String, dynamic>> _recommendedDrugs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final item = widget.item;
    final isHealthy = item.disease.toLowerCase().contains('sehat') ||
        item.disease.toLowerCase().contains('healthy');

    Map<String, dynamic>? pestData;
    List<Map<String, dynamic>> drugs = [];

    if (!isHealthy) {
      try {
        pestData = await _pestService.fetchDiseaseDetailByName(
          plantType: item.plantType,
          name: item.disease,
        );
      } catch (_) {}

      try {
        final jsonString =
            await rootBundle.loadString('katalog_obat_tanaman.json');
        final data = jsonDecode(jsonString) as List<dynamic>;

        final qPlant = item.plantType.toLowerCase();
        final qDisease = item.disease.toLowerCase();

        for (final entry in data) {
          final drug =
              Map<String, dynamic>.from(entry as Map<String, dynamic>);
          final tanamanRaw = drug['tanaman'];
          final sasaranRaw = drug['sasaran'];

          bool matchPlant = false;
          if (tanamanRaw is List) {
            matchPlant = tanamanRaw
                .any((t) => t.toString().toLowerCase().contains(qPlant));
          } else if (tanamanRaw != null) {
            matchPlant =
                tanamanRaw.toString().toLowerCase().contains(qPlant);
          }

          bool matchDisease = false;
          final sStr = sasaranRaw is List
              ? sasaranRaw.join(' ').toLowerCase()
              : sasaranRaw?.toString().toLowerCase() ?? '';

          if (sStr.contains(qDisease) || qDisease.contains(sStr)) {
            matchDisease = true;
          } else {
            final sTokens = sStr
                .split(RegExp(r'[^a-z0-9]'))
                .where((e) => e.length > 4);
            for (final t in sTokens) {
              if (qDisease.contains(t)) {
                matchDisease = true;
                break;
              }
            }
          }

          if (matchPlant && matchDisease) drugs.add(drug);
        }

        if (drugs.isEmpty) {
          for (final entry in data) {
            final drug =
                Map<String, dynamic>.from(entry as Map<String, dynamic>);
            final tanamanRaw = drug['tanaman'];
            bool matchPlant = false;
            if (tanamanRaw is List) {
              matchPlant = tanamanRaw
                  .any((t) => t.toString().toLowerCase().contains(qPlant));
            } else if (tanamanRaw != null) {
              matchPlant =
                  tanamanRaw.toString().toLowerCase().contains(qPlant);
            }
            if (matchPlant) drugs.add(drug);
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _pestData = pestData;
        _recommendedDrugs = drugs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isHealthy = item.disease.toLowerCase().contains('sehat') ||
        item.disease.toLowerCase().contains('healthy');
    final statusColor =
        isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);
    final statusBgColor = statusColor.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        title: const Text(
          'Detail Deteksi',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 280,
                        color: const Color(0xFFE8F5E9),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 280,
                        color: const Color(0xFFE8F5E9),
                        child: const Icon(Icons.broken_image_outlined,
                            size: 60, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header hasil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isHealthy
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_outlined,
                            color: statusColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Hasil Analisis',
                            style:
                                TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(
                          item.disease,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tingkat Kepercayaan',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${(item.confidence * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: item.confidence,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade100,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.eco_outlined,
                                  size: 14, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                              Text(
                                'Jenis: ${item.plantType}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_pestData != null) ...[
                    if (_pestData!['deskripsi_penyakit'] != null) ...[
                      _buildInfoSection('Deskripsi Penyakit',
                          _pestData!['deskripsi_penyakit']),
                      const SizedBox(height: 16),
                    ],

                    // Contoh visual
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contoh Visual Penyakit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              final placeholders = [
                                'https://images.unsplash.com/photo-1590680695028-d7607cb3ccb7?auto=format&fit=crop&q=80&w=400',
                                'https://images.unsplash.com/photo-1530836369250-ef71a3f5e481?auto=format&fit=crop&q=80&w=400',
                                'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?auto=format&fit=crop&q=80&w=400',
                              ];
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade200),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        placeholders[index],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 4, horizontal: 8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black
                                                    .withValues(alpha: 0.7),
                                                Colors.transparent
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                          ),
                                          child: Text(
                                            'Contoh ${index + 1}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (_pestData!['penanganan'] != null) ...[
                      _buildInfoSection(
                          'Langkah Penanganan', _pestData!['penanganan']),
                      const SizedBox(height: 16),
                    ],

                    if (_pestData!['obat'] != null &&
                        _recommendedDrugs.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.medication_liquid,
                                    color: AppColors.primaryGreen),
                                SizedBox(width: 8),
                                Text(
                                  'Saran Pengobatan',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _pestData!['obat'],
                              style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ] else if (!isHealthy) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Detail untuk penyakit ini belum tersedia di database.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_recommendedDrugs.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.medical_services_outlined,
                            color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text(
                          'Rekomendasi Produk Obat',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _recommendedDrugs.length,
                        itemBuilder: (context, index) {
                          final drug = _recommendedDrugs[index];
                          final name =
                              drug['nama'] ?? drug['nama_obat'] ?? '-';
                          final category = drug['kategori'] ?? '-';
                          String imageUrl = drug['gambar_url'] ?? '';
                          if (imageUrl.isEmpty) {
                            imageUrl =
                                'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&q=80&w=400';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DrugDetailScreen(drug: drug),
                                ),
                              );
                            },
                            child: Container(
                              width: 220,
                              margin: const EdgeInsets.only(
                                  right: 12, bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        const BorderRadius.horizontal(
                                            left: Radius.circular(16)),
                                    child: Image.network(
                                      imageUrl,
                                      width: 90,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 90,
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                            Icons
                                                .image_not_supported_outlined,
                                            color: Colors.grey[400]),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  const Color(0xFFE8F5E9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              category,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF2E7D32),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }
}
