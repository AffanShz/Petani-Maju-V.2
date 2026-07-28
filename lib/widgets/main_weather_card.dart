import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petani_maju/utils/weather_utils.dart';

class MainWeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final String? detailedLocation;
  final VoidCallback? onRefresh;

  const MainWeatherCard({
    super.key,
    this.weatherData,
    this.detailedLocation,
    this.onRefresh,
  });

  String getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  @override
  Widget build(BuildContext context) {
    if (weatherData == null) return const SizedBox();
    final main = weatherData!['main'];
    final weatherList = weatherData!['weather'];
    final Map<String, dynamic>? weather = (weatherList is List && weatherList.isNotEmpty && weatherList[0] is Map)
        ? Map<String, dynamic>.from(weatherList[0] as Map)
        : null;

    if (main == null || weather == null) return const SizedBox();

    final temp = (main['temp'] as num?)?.toStringAsFixed(0) ?? '--';

    // Use detailed location if available, otherwise fall back to API name
    String locationText = detailedLocation?.isNotEmpty == true
        ? detailedLocation!
        : weatherData!['name'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xff1B5E20),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(2, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            locationText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('$temp°',
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text(
                      WeatherUtils.translateWeather(weather['description']?.toString() ?? ''),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  CachedNetworkImage(
                    imageUrl: getIconUrl(weather['icon']?.toString() ?? '01d'),
                    width: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(Icons.cloud, color: Colors.white70, size: 48),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(Icons.cloud, color: Colors.white70, size: 48),
                    ),
                  ),
                  if (onRefresh != null)
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
