import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/session/domain/user_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, required this.onEdit});
  final UserEntity user;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => AppSurface(
    child: Padding(
      padding: AppSize.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: AppSize.inset(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSize.radius(14)),
                border: Border.all(color: const Color(0xFF53634E)),
              ),
              child: Text(
                Formatters.initials(user.name),
                style: TextStyle(
                  fontSize: AppSize.font(24),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'RobotoCondensed',
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSize.vertical(20)),
          Text(user.name, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: AppSize.vertical(6)),
          SelectableText(
            user.email,
            style: const TextStyle(color: AppColors.secondary),
          ),
          SizedBox(height: AppSize.vertical(24)),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profile'),
          ),
        ],
      ),
    ),
  );
}
