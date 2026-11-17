import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/navigation/not_found_page.dart';
import '../core/session/application/session_controller.dart';
import '../core/session/application/session_identity_provider.dart';
import '../core/session/domain/auth_state.dart';
import 'app_pages.dart';
import 'app_routes.dart';
import 'route_access_policy.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  String? redirect(BuildContext context, GoRouterState state) {
    final session = ref.read(sessionProvider);
    if (session.isLoading) return null;
    final path = state.uri.path;
    final isAuthPage =
        path == AppRoutes.loginPath || path == AppRoutes.registerPath;
    final auth = session.asData?.value;
    final authenticated = auth is Authenticated;
    final admin = auth is Authenticated && auth.user.isAdmin;
    if (authenticated && RouteAccessPolicy.isAdminPath(path) && !admin) {
      return AppRoutes.homePath;
    }
    if (admin && (isAuthPage || path == AppRoutes.homePath || path == '/')) {
      final destination = RouteAccessPolicy.redirectDestination(state.uri);
      return destination != null &&
              RouteAccessPolicy.isAdminPath(Uri.parse(destination).path)
          ? destination
          : AppRoutes.adminPath;
    }
    if (authenticated && isAuthPage) {
      final destination = RouteAccessPolicy.redirectDestination(state.uri);
      return destination != null &&
              !RouteAccessPolicy.isAdminPath(Uri.parse(destination).path)
          ? destination
          : AppRoutes.homePath;
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
  }

  final config = ValueNotifier(
    RoutingConfig(
      routes: createAppPages(rootKey, ref.read(sessionIdentityProvider)),
      redirect: redirect,
    ),
  );
  ref.listen(sessionIdentityProvider, (previous, next) {
    // Before the Router mounts, keep its original startup deep link intact.
    if (previous != next && rootKey.currentState != null) {
      config.value = RoutingConfig(
        routes: createAppPages(rootKey, ref.read(sessionIdentityProvider)),
        redirect: redirect,
      );
    }
  });
  ref.listen(
    sessionProvider.select(
      (session) => (
        loading: session.isLoading,
        authenticated: session.asData?.value is Authenticated,
        role: switch (session.asData?.value) {
          Authenticated(:final user) => user.role,
          _ => null,
        },
      ),
    ),
    (previous, next) => refresh.refresh(),
  );

  final router = GoRouter.routingConfig(
    navigatorKey: rootKey,
    routingConfig: config,
    initialLocation: AppRoutes.homePath,
    refreshListenable: refresh,
    errorBuilder: (context, state) => const NotFoundPage(),
  );
  ref.onDispose(() {
    router.dispose();
    config.dispose();
    refresh.dispose();
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
