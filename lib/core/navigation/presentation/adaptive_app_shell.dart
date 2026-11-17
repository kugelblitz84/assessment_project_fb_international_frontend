import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../config/demo_mode.dart';
import '../../responsive/adaptive_layout.dart';
import '../../theme/app_colors.dart';

const _destinations = [
  (
    name: AppRoutes.home,
    path: '/home',
    label: 'Explore',
    icon: Icons.grid_view_rounded,
  ),
  (
    name: AppRoutes.myBookings,
    path: '/bookings',
    label: 'Bookings',
    icon: Icons.calendar_month_outlined,
  ),
  (
    name: AppRoutes.assistant,
    path: '/assistant',
    label: 'AI Assistant',
    icon: Icons.auto_awesome_outlined,
  ),
  (
    name: AppRoutes.profile,
    path: '/profile',
    label: 'Profile',
    icon: Icons.person_outline_rounded,
  ),
];

class AutoCareBrand extends StatelessWidget {
  const AutoCareBrand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.directions_car_filled_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          'AutoCare',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
            color: light ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    ],
  );
}

class AdaptiveAppShell extends ConsumerWidget {
  const AdaptiveAppShell({
    super.key,
    required this.body,
    this.title,
    this.primary = false,
    this.bottomBar,
    this.actions = const [],
  });
  final Widget body;
  final String? title;
  final bool primary;
  final Widget? bottomBar;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final path = GoRouterState.of(context).uri.path;
    final selected = _destinations.indexWhere(
      (d) =>
          path == d.path ||
          (d.path != '/home' && path.startsWith('${d.path}/')),
    );
    void navigate(int index) => context.goNamed(_destinations[index].name);
    final nav = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(_destinations.length, (index) {
        final d = _destinations[index];
        return TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: selected == index ? AppColors.primarySoft : null,
            foregroundColor: selected == index
                ? AppColors.primary
                : AppColors.secondary,
          ),
          onPressed: () => navigate(index),
          icon: Icon(d.icon, size: 20),
          label: Text(d.label),
        );
      }),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Scaffold(
      appBar: desktop
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                largeText
                    ? 96 +
                          MediaQuery.textScalerOf(context).scale(22) * 1.5 +
                          MediaQuery.textScalerOf(context).scale(14) * 1.5
                    : MediaQuery.sizeOf(context).width < 1100
                    ? 144
                    : 80,
              ),
              child: Material(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1144),
                      child:
                          largeText || MediaQuery.sizeOf(context).width < 1100
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AutoCareBrand(),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: nav,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                const AutoCareBrand(),
                                const Spacer(),
                                nav,
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            )
          : AppBar(
              automaticallyImplyLeading: !primary,
              leading: !primary
                  ? IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.goNamed(AppRoutes.home),
                    )
                  : null,
              title: primary && title == null
                  ? const AutoCareBrand()
                  : Text(title ?? 'AutoCare'),
              actions: [
                if (primary && title == null)
                  IconButton(
                    tooltip: 'Your profile',
                    onPressed: () => context.goNamed(AppRoutes.profile),
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                ...actions,
              ],
            ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (ref.watch(demoModeProvider) && !keyboardOpen)
              Container(
                width: double.infinity,
                color: AppColors.pendingSoft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: const Text(
                  'Preview · Sample services and appointments',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.pending),
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: !desktop && primary && !keyboardOpen
          ? NavigationBar(
              height: largeText ? 94 : 80,
              labelBehavior: largeText
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: selected < 0 ? 0 : selected,
              onDestinationSelected: navigate,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            )
          : bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: Material(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: bottomBar,
                ),
              ),
            ),
    );
  }
}
