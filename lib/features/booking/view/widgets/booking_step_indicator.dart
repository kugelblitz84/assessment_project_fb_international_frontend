import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';

class BookingStepIndicator extends StatelessWidget {
  const BookingStepIndicator({
    super.key,
    required this.number,
    required this.label,
    required this.active,
  });
  final String number;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Container(
        padding: AppSize.inset(10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceRecessed,
          borderRadius: BorderRadius.circular(AppSize.radius(8)),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          number,
          style: TextStyle(
            fontSize: AppSize.font(13),
            fontWeight: FontWeight.w700,
            color: active ? AppColors.accent : AppColors.secondary,
          ),
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primary : AppColors.secondary,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );
}
