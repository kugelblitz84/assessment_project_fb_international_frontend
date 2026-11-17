import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/session/application/current_user_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentUserProvider.select((user) => user?.name));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          name == null ? 'Welcome' : 'Welcome, $name',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: AppSize.font(11),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: AppSize.vertical(4)),
        Text(
          'Keep your drive in its prime.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
