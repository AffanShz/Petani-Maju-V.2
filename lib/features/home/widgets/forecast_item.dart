import 'package:flutter/material.dart';

class ForecastItem extends StatelessWidget {
  final String day;
  final IconData icon;
  final Color iconColor;
  final String maxTemp;
  final String minTemp;

  const ForecastItem({
    super.key,
    required this.day,
    required this.icon,
    required this.iconColor,
    required this.maxTemp,
    required this.minTemp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
          Column(
            children: [
              Text(
                maxTemp,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '°$minTemp°',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
