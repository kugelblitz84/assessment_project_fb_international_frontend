import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/session/application/current_user_provider.dart';
import '../../../../core/theme/app_colors.dart';

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
          style: const TextStyle(color: AppColors.secondary),
        ),
        SizedBox(height: AppSize.vertical(4)),
        Text(
          'A little care. A better drive.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
