import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:petani_maju/utils/weather_utils.dart';

/// Widget untuk menampilkan kartu cuaca utama dengan gradient dinamis
class MainWeatherCard extends StatelessWidget {
  final Map<String, dynamic> currentWeather;
  final String? detailedLocation;

  const MainWeatherCard({
    super.key,
    required this.currentWeather,
    this.detailedLocation,
  });

  @override
  Widget build(BuildContext context) {
    final main = currentWeather['main'];
    final weather = currentWeather['weather'][0];
    final weatherMain = weather['main'] as String?;
    final gradientColors = _getWeatherGradient(weatherMain);
    final now = DateTime.now();

    String locationText = detailedLocation?.isNotEmpty == true
        ? detailedLocation!
        : currentWeather['name'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  locationText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Weather Icon
          weather['icon'] != null
              ? CachedNetworkImage(
                  imageUrl:
                      'https://openweathermap.org/img/wn/${weather['icon']}@4x.png',
                  width: 120,
                  height: 120,
                  placeholder: (context, url) => Icon(
                    _getWeatherIcon(weatherMain),
                    size: 80,
                    color: Colors.white70,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    _getWeatherIcon(weatherMain),
                    size: 80,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _getWeatherIcon(weatherMain),
                  size: 80,
                  color: Colors.white,
                ),
          const SizedBox(height: 16),
          // Temperature
          Text(
            '${main['temp'].toStringAsFixed(0)}°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Description
          Text(
            WeatherUtils.translateWeather(weather['description']),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          // Info Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              WeatherInfoItem(
                icon: Icons.water_drop,
                value: '${main['humidity']}%',
                label: 'Kelembaban',
              ),
              WeatherInfoItem(
                icon: Icons.air,
                value: '${currentWeather['wind']['speed']} m/s',
                label: 'Angin',
              ),
              WeatherInfoItem(
                icon: Icons.thermostat,
                value: '${main['feels_like'].toStringAsFixed(0)}°',
                label: 'Terasa',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getWeatherGradient(String? weatherMain) {
    switch (weatherMain?.toLowerCase()) {
      case 'clear':
        return [const Color(0xFFFF8C00), const Color(0xFFFFD700)];
      case 'clouds':
        return [const Color(0xFF546E7A), const Color(0xFF90A4AE)];
      case 'rain':
      case 'drizzle':
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      case 'thunderstorm':
        return [const Color(0xFF37474F), const Color(0xFF546E7A)];
      case 'snow':
        return [const Color(0xFFB3E5FC), const Color(0xFFE1F5FE)];
      case 'mist':
      case 'haze':
      case 'fog':
        return [const Color(0xFF78909C), const Color(0xFFB0BEC5)];
      default:
        return [const Color(0xff1B5E20), const Color(0xff4CAF50)];
    }
  }

  IconData _getWeatherIcon(String? weatherMain) {
    switch (weatherMain?.toLowerCase()) {
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
      case 'mist':
      case 'haze':
      case 'fog':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }
}

/// Widget kecil untuk menampilkan info cuaca (humidity, wind, feels like)
class WeatherInfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const WeatherInfoItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
