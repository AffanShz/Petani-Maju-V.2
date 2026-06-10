import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class DailyForecastWidget extends StatelessWidget {
  final List<dynamic> dailyData;

  const DailyForecastWidget({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perkiraan 6 Hari',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...dailyData.asMap().entries.map((entry) {
            return _buildDayRow(context, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildDayRow(BuildContext context, Map<String, dynamic> day) {
    final DateTime date = day['date'];
    final bool isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;
    final String dayName = isToday
        ? 'common.today'.tr()
        : DateFormat('EEEE', context.locale.toString()).format(date);
    final String dateText =
        DateFormat('d MMM', context.locale.toString()).format(date);

    final double pop =
        day['pop'] != null ? (day['pop'] as num).toDouble() * 100 : 0;
    final int minTemp = (day['minTemp'] as num).round();
    final int maxTemp = (day['maxTemp'] as num).round();
    final String icon = day['icon'];
    final String weatherMain = day['weatherMain'] ?? 'Clouds';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Day name and date
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayName,
                    style: TextStyle(
                        color: isToday ? Colors.black87 : Colors.grey[700],
                        fontSize: 14,
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.w500)),
                Text(dateText,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),

          // Rain chance with blue droplet
          if (pop > 0) ...[
            Icon(Icons.water_drop, color: Colors.blue[400], size: 12),
            const SizedBox(width: 2),
            Text('${pop.round()}%',
                style: TextStyle(color: Colors.blue[400], fontSize: 12)),
            const SizedBox(width: 8),
          ],

          // Weather Icon
          CachedNetworkImage(
            imageUrl: 'https://openweathermap.org/img/wn/$icon@2x.png',
            width: 32,
            height: 32,
            placeholder: (_, __) => Icon(
              _getWeatherIconData(weatherMain),
              size: 20,
              color: _getWeatherColor(weatherMain),
            ),
            errorWidget: (_, __, ___) => Icon(
              _getWeatherIconData(weatherMain),
              color: _getWeatherColor(weatherMain),
              size: 20,
            ),
          ),

          const SizedBox(width: 8),

          // Max Temp (bold) / Min Temp (dim)
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$maxTemp°',
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text('$minTemp°',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getWeatherColor(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return const Color(0xFFFF9800);
      case 'clouds':
        return const Color(0xFF78909C);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF42A5F5);
      case 'thunderstorm':
        return const Color(0xFF5C6BC0);
      case 'snow':
        return const Color(0xFF90CAF9);
      default:
        return const Color(0xFF78909C);
    }
  }

  IconData _getWeatherIconData(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }
}
