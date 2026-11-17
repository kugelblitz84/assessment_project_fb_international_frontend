import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/app/widgets/auto_care_brand.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_depth.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';

const appDestinations = [
  (label: 'Explore', icon: Icons.grid_view_rounded),
  (label: 'Bookings', icon: Icons.calendar_month_outlined),
  (label: 'AI Assistant', icon: Icons.auto_awesome_outlined),
  (label: 'Profile', icon: Icons.person_outline_rounded),
];

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppDepth.floating),
      child: NavigationBar(
        height: largeText ? 94 : 80,
        labelBehavior: largeText
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final d in appDestinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}

class DesktopNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DesktopNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.height,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;
  static double heightFor(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) > 22
      ? 96 +
            MediaQuery.textScalerOf(context).scale(22) * 1.5 +
            MediaQuery.textScalerOf(context).scale(14) * 1.5
      : MediaQuery.sizeOf(context).width < 1100
      ? 144
      : 80;
  @override
  Size get preferredSize => Size.fromHeight(height);
  @override
  Widget build(BuildContext context) {
    final stacked =
        MediaQuery.textScalerOf(context).scale(16) > 22 ||
        MediaQuery.sizeOf(context).width < 1100;
    final nav = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceRecessed,
        borderRadius: BorderRadius.circular(AppSize.radius(13)),
        border: Border.all(color: AppColors.border.withValues(alpha: .7)),
      ),
      child: Wrap(
        spacing: 3,
        runSpacing: 4,
        children: [
          for (var i = 0; i < appDestinations.length; i++)
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: selectedIndex == i ? AppColors.surface : null,
                elevation: selectedIndex == i ? 2 : 0,
                shadowColor: AppColors.shadow.withValues(alpha: .5),
                foregroundColor: selectedIndex == i
                    ? AppColors.primary
                    : AppColors.secondary,
              ),
              onPressed: () => onSelected(i),
              icon: Icon(appDestinations[i].icon, size: AppSize.icon(20)),
              label: Text(appDestinations[i].label),
            ),
        ],
      ),
    );
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.horizontal(24),
            vertical: AppSize.vertical(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1144),
            child: stacked
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AutoCareBrand(),
                      SizedBox(height: AppSize.vertical(8)),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: nav,
                      ),
                    ],
                  )
                : Row(children: [const AutoCareBrand(), const Spacer(), nav]),
          ),
        ),
      ),
    );
  }
}
