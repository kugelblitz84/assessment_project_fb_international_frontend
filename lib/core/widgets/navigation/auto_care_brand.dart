import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_depth.dart';

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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF414D44), AppColors.graphite],
          ),
          borderRadius: BorderRadius.circular(AppSize.radius(10)),
          border: Border.all(color: Colors.white.withValues(alpha: .2)),
          boxShadow: light ? null : AppDepth.control,
        ),
        child: Icon(
          Icons.speed_rounded,
          color: AppColors.accent,
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
            fontFamily: 'RobotoCondensed',
            fontSize: AppSize.font(25),
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
            color: light ? Colors.white : AppColors.graphite,
          ),
        ),
      ),
    ],
  );
}
