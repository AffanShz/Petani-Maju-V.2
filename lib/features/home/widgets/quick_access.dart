import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/features/home/widgets/quick_access_item.dart';
import 'package:petani_maju/features/weather/screens/weather_detail_screen.dart';
import 'package:petani_maju/features/pests/screens/pest_screen.dart';
import 'package:petani_maju/features/drugs/screens/drug_screen.dart';

class QuickAccess extends StatelessWidget {
  const QuickAccess({super.key});

  /// Tinggi seragam untuk semua kartu akses cepat.
  ///
  /// Wrap menghitung tinggi tiap anak sendiri-sendiri, sehingga kartu yang
  /// judulnya turun ke baris kedua ("Hama & Penyakit") jadi lebih jangkung
  /// dari yang satu baris ("Info Cuaca"). Dikunci ke satu tinggi yang cukup
  /// untuk kasus terpanjang, dan ikut skala font sistem supaya tetap seragam
  /// saat ukuran teks diperbesar.
  double _itemHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    const double iconBlock = 44; // padding 10*2 + ikon 24
    const double gaps = 12 + 4;
    const double cardPadding = 32; // 16 atas + 16 bawah
    final double title = 16 * 1.25 * 2 * scale;
    final double subtitle = 12 * 1.25 * 2 * scale;
    return iconBlock + gaps + cardPadding + title + subtitle;
  }

  @override
  Widget build(BuildContext context) {
    // 48 is horizontal padding of parent (24 * 2)
    final double itemWidth = (MediaQuery.of(context).size.width - 48 - 12) / 2;
    final double itemHeight = _itemHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.quick_access'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: QuickAccessItem(
                icon: Icons.cloud_outlined,
                title: 'home.menu_weather'.tr(),
                subtitle: 'Prakiraan 7 hari',
                iconColor: const Color(0xFF2196F3), // Blue
                backgroundColor: const Color(0xFFE3F2FD), // Light blue
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeatherDetailScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: QuickAccessItem(
                icon: Icons.bug_report_outlined,
                title: 'home.menu_pests'.tr(),
                subtitle: 'Penyakit tanaman',
                iconColor: Colors.red, // Red
                backgroundColor: Colors.red.shade50, // Light red
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PestScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: QuickAccessItem(
                icon: Icons.healing_outlined,
                title: 'home.menu_drugs'.tr(),
                subtitle: 'Pencegahan & resep',
                iconColor: Colors.green.shade700, // Green
                backgroundColor: Colors.green.shade50, // Light green
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DrugScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
