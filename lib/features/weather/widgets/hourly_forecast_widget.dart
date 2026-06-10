import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class HourlyForecastWidget extends StatelessWidget {
  final List<dynamic> hourlyForecast;

  const HourlyForecastWidget({super.key, required this.hourlyForecast});

  @override
  Widget build(BuildContext context) {
    if (hourlyForecast.isEmpty) {
      return const SizedBox();
    }

    // Filter to start from current time or near future
    final now = DateTime.now();
    final futureItems = hourlyForecast.where((item) {
      try {
        final date = DateTime.parse(item['dt_txt']);
        return date.isAfter(now.subtract(const Duration(hours: 3)));
      } catch (e) {
        return false;
      }
    }).toList();

    // Take next 8 items (24 hours approx with 3-hour intervals)
    final items = futureItems.take(8).toList();
    if (items.isEmpty) {
      return const SizedBox();
    }

    final double itemWidth = 65.0;
    final double totalWidth = items.length * itemWidth;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
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
            'Perkiraan Per Jam',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              height: 180,
              child: Stack(
                children: [
                  // Graph line layer (behind everything)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TemperatureLinePainter(items),
                    ),
                  ),
                  // Content layer (on top of graph)
                  Row(
                    children: items.asMap().entries.map((entry) {
                      final item = entry.value;
                      return _buildHourItem(item, itemWidth);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourItem(dynamic item, double width) {
    try {
      final date = DateTime.parse(item['dt_txt']);
      final time = DateFormat('HH:00').format(date);
      final icon = item['weather'][0]['icon'] as String;
      final weatherMain = item['weather'][0]['main'] as String;
      final pop = ((item['pop'] as num?)?.toDouble() ?? 0) * 100;
      final temp = (item['main']['temp'] as num).round();

      return SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top section: Time
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Weather Icon
            CachedNetworkImage(
              imageUrl: 'https://openweathermap.org/img/wn/$icon@2x.png',
              width: 32,
              height: 32,
              placeholder: (_, __) => Icon(
                _getWeatherIconData(weatherMain),
                size: 24,
                color: _getWeatherColor(weatherMain),
              ),
              errorWidget: (_, __, ___) => Icon(
                _getWeatherIconData(weatherMain),
                size: 24,
                color: _getWeatherColor(weatherMain),
              ),
            ),
            // Temperature
            Text(
              '$temp°',
              style: TextStyle(
                color: _getWeatherColor(weatherMain),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Spacer for graph area (graph is drawn behind by CustomPaint)
            const SizedBox(height: 40),
            // Bottom: Rain percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop, size: 10, color: Colors.blue[400]),
                const SizedBox(width: 2),
                Text(
                  '${pop.round()}%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return SizedBox(width: width);
    }
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
      case 'mist':
      case 'haze':
      case 'fog':
        return const Color(0xFFB0BEC5);
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
      case 'mist':
      case 'haze':
      case 'fog':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }
}

/// CustomPainter for drawing temperature line graph
class _TemperatureLinePainter extends CustomPainter {
  final List<dynamic> items;

  _TemperatureLinePainter(this.items);

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    // Calculate min/max for scaling
    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;

    for (var item in items) {
      double t = (item['main']['temp'] as num).toDouble();
      if (t < minTemp) minTemp = t;
      if (t > maxTemp) maxTemp = t;
    }

    // Add padding to range
    minTemp -= 1;
    maxTemp += 1;
    final tempRange = maxTemp - minTemp;
    if (tempRange == 0) return;

    // Graph area - positioned in the middle section
    final graphTop = 100.0;
    final graphBottom = size.height - 30.0;
    final graphHeight = graphBottom - graphTop;

    final itemWidth = size.width / items.length;

    // Paint for the connecting line
    final linePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paint for dots
    final dotPaint = Paint()
      ..color = Colors.grey[500]!
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Calculate points
    List<Offset> points = [];
    for (int i = 0; i < items.length; i++) {
      double temp = (items[i]['main']['temp'] as num).toDouble();
      double normalized = (temp - minTemp) / tempRange;

      double x = itemWidth * i + (itemWidth / 2);
      double y = graphBottom - (normalized * graphHeight);

      points.add(Offset(x, y));
    }

    // Draw connecting line with smooth curve
    if (points.length >= 2) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];

        final controlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      canvas.drawPath(path, linePaint);
    }

    // Draw dots at each point
    for (var point in points) {
      canvas.drawCircle(point, 6, dotBorderPaint);
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
