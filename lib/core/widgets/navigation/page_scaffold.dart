import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_spacing.dart';
import '../../../routes/app_routes.dart';
import '../../config/demo_mode.dart';
import '../responsive/adaptive_layout.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_depth.dart';
import 'navigation_bars.dart';
import 'navigation_shell_scope.dart';

/// Secondary screens supply their own header and omit primary bottom navigation.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.body,
    this.title,
    this.bottomBar,
    this.actions = const [],
  });
  final Widget body;
  final String? title;
  final Widget? bottomBar;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: desktop
          ? DesktopNavigationBar(
              selectedIndex:
                  NavigationShellScope.maybeOf(context)?.widget.currentIndex ??
                  -1,
              onSelected: (index) {
                FocusManager.instance.primaryFocus?.unfocus();
                final shell = NavigationShellScope.maybeOf(context);
                if (shell != null) {
                  shell.goBranch(index);
                } else {
                  context.goNamed(
                    [
                      AppRoutes.home,
                      AppRoutes.myBookings,
                      AppRoutes.assistant,
                      AppRoutes.profile,
                    ][index],
                  );
                }
              },
              height: DesktopNavigationBar.heightFor(context),
            )
          : AppBar(
              title: Text(title ?? 'AutoCare'),
              actions: actions,
              leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.goNamed(AppRoutes.home),
              ),
            ),
      body: DemoPageBody(child: body),
      bottomNavigationBar: bottomBar == null
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(boxShadow: AppDepth.floating),
              child: SafeArea(
                top: false,
                child: Material(
                  color: AppColors.surface,
                  child: Padding(padding: AppSize.inset(16), child: bottomBar),
                ),
              ),
            ),
    );
  }
}

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
