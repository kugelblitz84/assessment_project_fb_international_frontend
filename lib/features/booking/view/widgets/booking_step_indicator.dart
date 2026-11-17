import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

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
      CircleAvatar(
        radius: AppSize.radius(15),
        backgroundColor: active ? AppColors.primary : AppColors.border,
        foregroundColor: active ? Colors.white : AppColors.secondary,
        child: Text(number, style: TextStyle(fontSize: AppSize.font(13))),
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
