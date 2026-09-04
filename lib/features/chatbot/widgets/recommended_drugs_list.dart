import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:agrinova/core/constants/colors.dart';
import 'package:agrinova/features/drugs/screens/drug_screen.dart';
import 'package:agrinova/features/drugs/screens/drug_detail_screen.dart';

/// Daftar obat yang direkomendasikan AI, tampil mendatar di bawah jawaban.
///
/// Dipisah dari ChatBubble supaya tata letaknya bisa diuji sendiri: bagian ini
/// yang meluber saat ukuran teks sistem diperbesar.
class RecommendedDrugsList extends StatelessWidget {
  final List<Map<String, dynamic>> drugs;

  const RecommendedDrugsList({super.key, required this.drugs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Row(
                    children: [
                      Icon(Icons.medical_services_outlined,
                          size: 15, color: AppColors.primaryGreen),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Rekomendasi Produk Obat:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DrugScreen()),
                      );
                    },
                    child: Shimmer.fromColors(
                      baseColor: AppColors.primaryGreen,
                      highlightColor: const Color(0xFFAED581),
                      period: const Duration(milliseconds: 2000),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Katalog Lengkap',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: AppColors.primaryGreen),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Daftar tanpa tinggi tetap.
          //
          // Sebelumnya bungkusnya dikunci 145px dengan ListView di dalam
          // Expanded. Nama obat, chip kategori dan bahan aktif ikut membesar
          // mengikuti skala font sistem, jadi tinggi mati itu pasti pecah
          // cepat atau lambat. IntrinsicHeight membuat baris setinggi kartu
          // yang paling tinggi, dan semua kartu ikut setinggi itu.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final drug in drugs) _buildDrugCard(context, drug),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Satu kartu obat dalam daftar rekomendasi.
  Widget _buildDrugCard(BuildContext context, Map<String, dynamic> drug) {
    final name = drug['nama_obat'] ?? drug['nama'] ?? 'Obat';
    final category = drug['kategori'] ?? 'Pertanian';
    final activeMat = drug['bahan_aktif'] ?? '';
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
            builder: (_) => DrugDetailScreen(drug: drug),
          ),
        );
      },
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 10, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          // Gambar mengisi tinggi kartu lewat stretch, bukan lewat tinggi tak
          // hingga: IntrinsicHeight harus bisa mengukur anaknya.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(13),
              ),
              child: Image.network(
                imageUrl,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey[400]),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (activeMat.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        activeMat.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
