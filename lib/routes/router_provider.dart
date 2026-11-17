import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/presentation/not_found_page.dart';
import '../core/session/application/session_controller.dart';
import '../core/session/domain/auth_state.dart';
import 'app_pages.dart';
import 'app_routes.dart';
import 'route_access_policy.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(sessionProvider, (previous, next) => refresh.refresh());

  final router = GoRouter(
    initialLocation: AppRoutes.homePath,
    routes: appPages,
    refreshListenable: refresh,
    errorBuilder: (context, state) => const NotFoundPage(),
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      if (session.isLoading) return null;
      final path = state.uri.path;
      final isAuthPage =
          path == AppRoutes.loginPath || path == AppRoutes.registerPath;
      final authenticated = session.asData?.value is Authenticated;
      if (authenticated && isAuthPage) {
        return RouteAccessPolicy.redirectDestination(state.uri) ??
            AppRoutes.homePath;
      }
      if (!authenticated && RouteAccessPolicy.requiresAuthentication(path)) {
        return RouteAccessPolicy.location(
          AppRoutes.loginPath,
          RouteAccessPolicy.validateDestination(state.uri.toString()),
        );
      }
      if (isAuthPage &&
          state.uri.hasQuery &&
          RouteAccessPolicy.redirectDestination(state.uri) == null) {
        return path;
      }
      return null;
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
