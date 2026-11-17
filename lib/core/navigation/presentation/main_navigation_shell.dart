import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../responsive/adaptive_layout.dart';
import 'auto_care_brand.dart';
import 'navigation_bars.dart';
import 'page_scaffold.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({
    super.key,
    required this.navigationShell,
    this.showNavigation = true,
  });
  final StatefulNavigationShell navigationShell;
  final bool showNavigation;

  void _select(int index) {
    // Reselecting a tab deliberately preserves its stack, scroll, and filters.
    if (index == navigationShell.currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    // Branch-owned secondary screens provide their own page scaffold. The
    // navigation shell's GlobalKey preserves its navigators through this change.
    if (!showNavigation) {
      // Inactive primary pages remain mounted and still need a Material ancestor.
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: navigationShell,
      );
    }
    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    final index = navigationShell.currentIndex;
    return Scaffold(
      appBar: desktop
          ? DesktopNavigationBar(
              selectedIndex: index,
              onSelected: _select,
              height: DesktopNavigationBar.heightFor(context),
            )
          : AppBar(
              automaticallyImplyLeading: false,
              title: index == 0
                  ? const AutoCareBrand()
                  : Text(['', 'My bookings', 'AI assistant', 'Profile'][index]),
              actions: [
                if (index == 0)
                  IconButton(
                    tooltip: 'Your profile',
                    onPressed: () => _select(3),
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
              ],
            ),
      body: DemoPageBody(child: navigationShell),
      bottomNavigationBar:
          !desktop && MediaQuery.viewInsetsOf(context).bottom == 0
          ? AppBottomNavigationBar(selectedIndex: index, onSelected: _select)
          : null,
    );
  }
}
