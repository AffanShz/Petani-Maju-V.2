import 'package:flutter/material.dart';
import 'package:petani_maju/core/constants/colors.dart';

class WeatherAlert extends StatelessWidget {
  final String message;

  const WeatherAlert({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red, 
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined, 
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERINGATAN CUACA!', 
                  style: TextStyle(
                    color: Colors.red[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.red[900],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
