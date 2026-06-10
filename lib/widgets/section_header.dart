import 'package:flutter/material.dart';
import 'package:petani_maju/core/constants/colors.dart';
import 'package:easy_localization/easy_localization.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Row(
            children: [
              Text(
                actionText ?? 'home.see_all'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
