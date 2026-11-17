import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/app/shell/navigation_bars.dart';
import 'package:assessment_project_fb_international_frontend/app/shell/navigation_shell_scope.dart';
import 'package:assessment_project_fb_international_frontend/app/widgets/demo_page_body.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_depth.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/responsive/adaptive_layout.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

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
