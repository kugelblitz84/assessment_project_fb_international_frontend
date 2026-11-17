import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'routes/router_provider.dart';
import 'core/session/application/session_controller.dart';
import 'core/session/presentation/bootstrap_view.dart';

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
        routerConfig: router,
        builder: (context, child) => Consumer(
          builder: (context, ref, _) {
            // Omit the Router subtree entirely until restoration resolves, so
            // protected pages cannot mount or start requests during startup/retry.
            return ref.watch(sessionProvider).isLoading
                ? const BootstrapView()
                : child ?? const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
