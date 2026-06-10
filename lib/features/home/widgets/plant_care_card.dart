import 'package:flutter/material.dart';

class PlantCareCard extends StatelessWidget {
  final String title;
  final String advice;
  final bool isUrgent;

  const PlantCareCard({
    super.key,
    required this.title,
    required this.advice,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        isUrgent ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9);
    final Color borderColor = isUrgent ? Colors.orange : Colors.green;
    final Color iconColor = isUrgent ? Colors.orange[800]! : Colors.green[700]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor.withOpacity(0.2)),
            ),
            child: Icon(
              isUrgent ? Icons.priority_high_rounded : Icons.spa_rounded,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
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
