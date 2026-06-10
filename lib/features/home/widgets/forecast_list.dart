import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/utils/weather_utils.dart';

class ForecastList extends StatelessWidget {
  final List<dynamic> forecastData;

  const ForecastList({super.key, required this.forecastData});

  String getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  // Filter forecast to show approximately every 4 hours
  // OpenWeatherMap provides 3-hour intervals, so we take every other item (6 hours)
  // or filter by specific hours like 00:00, 06:00, 12:00, 18:00
  List<dynamic> _filterForecastFor4Hours(List<dynamic> data) {
    List<dynamic> filtered = [];

    for (var item in data) {
      DateTime date = DateTime.parse(item['dt_txt']);
      int hour = date.hour;

      // Show forecasts at 00:00, 06:00, 12:00, 18:00 (approximately every 4-6 hours)
      if (hour == 0 || hour == 6 || hour == 12 || hour == 18) {
        filtered.add(item);
      }
    }

    // If no filtered items (edge case), return first few items
    if (filtered.isEmpty && data.isNotEmpty) {
      return data.take(8).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filterForecastFor4Hours(forecastData);

    return SizedBox(
      height: 190, // Increased height for date info
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filteredData.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          var item = filteredData[index];
          DateTime date = DateTime.parse(item['dt_txt']);

          String dayName = DateFormat('EEEE', context.locale.toString())
              .format(date); // Full day name
          String dateText = DateFormat('d MMM', context.locale.toString())
              .format(date); // e.g., "14 Des"
          String timeText = DateFormat('HH:mm').format(date);
          String temp = item['main']['temp'].toStringAsFixed(0);
          String iconCode = item['weather'][0]['icon'];
          String description = item['weather'][0]['description'];

          return Container(
            width: 110,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Day name
                Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Date
                Text(
                  dateText,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                // Time
                Text(
                  timeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                CachedNetworkImage(
                  imageUrl: getIconUrl(iconCode),
                  width: 36,
                  height: 36,
                  placeholder: (context, url) => const Icon(
                    Icons.cloud,
                    size: 36,
                    color: Colors.grey,
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.cloud,
                    size: 36,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$temp°',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  WeatherUtils.translateWeather(description),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    height: 1.1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
