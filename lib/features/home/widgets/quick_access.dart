import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/features/home/widgets/quick_access_item.dart';
import 'package:petani_maju/features/home/widgets/quick_access_metrics.dart';
import 'package:petani_maju/features/weather/screens/weather_detail_screen.dart';
import 'package:petani_maju/features/pests/screens/pest_screen.dart';
import 'package:petani_maju/features/drugs/screens/drug_screen.dart';

/// Satu entri di grid akses cepat.
class _QuickAccessEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color backgroundColor;
  final WidgetBuilder destination;

  const _QuickAccessEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.backgroundColor,
    required this.destination,
  });
}

class QuickAccess extends StatelessWidget {
  const QuickAccess({super.key});

  List<_QuickAccessEntry> _entries(BuildContext context) => [
        _QuickAccessEntry(
          icon: Icons.cloud_outlined,
          title: 'home.menu_weather'.tr(),
          subtitle: 'Prakiraan 7 hari',
          iconColor: const Color(0xFF2196F3),
          backgroundColor: const Color(0xFFE3F2FD),
          destination: (_) => const WeatherDetailScreen(),
        ),
        _QuickAccessEntry(
          icon: Icons.bug_report_outlined,
          title: 'home.menu_pests'.tr(),
          subtitle: 'Penyakit tanaman',
          iconColor: Colors.red,
          backgroundColor: Colors.red.shade50,
          destination: (_) => const PestScreen(),
        ),
        _QuickAccessEntry(
          icon: Icons.healing_outlined,
          title: 'home.menu_drugs'.tr(),
          subtitle: 'Pencegahan & resep',
          iconColor: Colors.green.shade700,
          backgroundColor: Colors.green.shade50,
          destination: (_) => const DrugScreen(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    // 48 is horizontal padding of parent (24 * 2)
    final double itemWidth = (MediaQuery.of(context).size.width - 48 - 12) / 2;
    final entries = _entries(context);
    final double itemHeight = quickAccessCardHeight(
      context,
      entries.map((e) => (title: e.title, subtitle: e.subtitle)),
      itemWidth,
    );

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
            for (final entry in entries)
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: QuickAccessItem(
                  icon: entry.icon,
                  title: entry.title,
                  subtitle: entry.subtitle,
                  iconColor: entry.iconColor,
                  backgroundColor: entry.backgroundColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: entry.destination),
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
