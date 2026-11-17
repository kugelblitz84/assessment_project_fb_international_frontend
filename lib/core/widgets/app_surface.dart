import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_depth.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';

/// Shared panel treatment keeps highlights, depth and ink interactions consistent.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: AppSize.cardRadius,
      boxShadow: AppDepth.raised,
    ),
    child: Material(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: AppSize.cardRadius,
        side: const BorderSide(color: AppColors.highlight, width: .8),
      ),
      child: child,
    ),
  );
}
