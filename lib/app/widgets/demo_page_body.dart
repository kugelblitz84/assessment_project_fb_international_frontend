import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';

class DemoPageBody extends ConsumerWidget {
  const DemoPageBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    top: false,
    bottom: false,
    child: Column(
      children: [
        if (ref.watch(demoModeProvider) &&
            MediaQuery.viewInsetsOf(context).bottom == 0)
          Container(
            width: double.infinity,
            color: AppColors.surfaceRecessed,
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.horizontal(16),
              vertical: AppSize.vertical(5),
            ),
            child: Text(
              'Preview · Sample services and appointments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSize.font(12),
                color: AppColors.secondary,
              ),
            ),
          ),
        Expanded(child: child),
      ],
    ),
  );
}
