import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:assessment_project_fb_international_frontend/app/widgets/bootstrap_view.dart';
import 'package:assessment_project_fb_international_frontend/core/bootstrap/view/bootstrap_gate.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_theme.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        title: 'AutoCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: router,
        builder: (context, child) => BootstrapGate(
          loading: const BootstrapView(),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
