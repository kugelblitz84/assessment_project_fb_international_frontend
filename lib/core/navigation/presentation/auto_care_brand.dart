import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';

class AutoCareBrand extends StatelessWidget {
  const AutoCareBrand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: AppSize.inset(8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSize.radius(10)),
        ),
        child: Icon(
          Icons.directions_car_filled_rounded,
          color: Colors.white,
          size: AppSize.icon(23),
        ),
      ),
      SizedBox(width: AppSize.horizontal(10)),
      Flexible(
        child: Text(
          'AutoCare',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppSize.font(22),
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
            color: light ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    ],
  );
}
