import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/app/widgets/auto_care_brand.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_surface.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.busy = false,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final bool busy;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: AppSize.inset(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AutoCareBrand()),
                SizedBox(height: AppSize.vertical(32)),
                AppSurface(
                  child: Padding(
                    padding: AppSize.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: AppSize.vertical(8)),
                        Text(
                          subtitle,
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                        SizedBox(height: AppSize.vertical(28)),
                        child,
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSize.vertical(12)),
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () => context.goNamed(AppRoutes.home),
                  icon: Icon(Icons.arrow_back, size: AppSize.icon(18)),
                  label: const Text('Continue browsing'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
