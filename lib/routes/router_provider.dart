import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/presentation/not_found_page.dart';
import '../core/session/application/session_controller.dart';
import '../core/session/domain/auth_state.dart';
import 'app_pages.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(sessionProvider, (previous, next) => refresh.refresh());

  final router = GoRouter(
    initialLocation: AppRoutes.bootstrapPath,
    routes: appPages,
    refreshListenable: refresh,
    errorBuilder: (context, state) => const NotFoundPage(),
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.uri.path;
      if (session.isLoading) {
        return path == AppRoutes.bootstrapPath ? null : AppRoutes.bootstrapPath;
      }
      if (session.hasError) {
        return path == AppRoutes.bootstrapErrorPath
            ? null
            : AppRoutes.bootstrapErrorPath;
      }

      final isAuthPage =
          path == AppRoutes.loginPath || path == AppRoutes.registerPath;
      final isBootstrapPage =
          path == AppRoutes.bootstrapPath ||
          path == AppRoutes.bootstrapErrorPath;
      if (session.asData?.value is Authenticated) {
        return isAuthPage || isBootstrapPage ? AppRoutes.homePath : null;
      }
      return isAuthPage ? null : AppRoutes.loginPath;
    },
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
