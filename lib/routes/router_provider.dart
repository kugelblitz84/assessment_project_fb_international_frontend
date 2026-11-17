import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/presentation/not_found_page.dart';
import '../core/onboarding/onboarding_provider.dart';
import '../core/session/application/session_controller.dart';
import '../core/session/domain/auth_state.dart';
import 'app_pages.dart';
import 'app_routes.dart';
import 'route_access_policy.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  var loggedOut = false;
  ref.listen(sessionProvider, (previous, next) {
    if (next.asData?.value case Unauthenticated(didLogout: true)) {
      loggedOut = true;
    }
    refresh.refresh();
  });
  ref.listen(onboardingProvider, (previous, next) => refresh.refresh());

  final router = GoRouter(
    initialLocation: AppRoutes.bootstrapPath,
    routes: appPages,
    refreshListenable: refresh,
    errorBuilder: (context, state) => const NotFoundPage(),
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final onboarding = ref.read(onboardingProvider);
      final path = state.uri.path;
      final isAuthPage =
          path == AppRoutes.loginPath || path == AppRoutes.registerPath;
      final isGate =
          path == AppRoutes.bootstrapPath ||
          path == AppRoutes.bootstrapErrorPath ||
          path == AppRoutes.onboardingPath;
      final destination = isGate || isAuthPage
          ? RouteAccessPolicy.redirectDestination(state.uri)
          : RouteAccessPolicy.validateDestination(state.uri.toString());
      if (session.isLoading || onboarding.isLoading) {
        return path == AppRoutes.bootstrapPath
            ? null
            : RouteAccessPolicy.location(AppRoutes.bootstrapPath, destination);
      }
      if (onboarding.hasError) {
        return path == AppRoutes.bootstrapErrorPath
            ? null
            : RouteAccessPolicy.location(
                AppRoutes.bootstrapErrorPath,
                destination,
              );
      }
      if (onboarding.asData?.value != true) {
        return path == AppRoutes.onboardingPath
            ? null
            : RouteAccessPolicy.location(AppRoutes.onboardingPath, destination);
      }
      if (loggedOut) {
        loggedOut = false;
        return path == AppRoutes.homePath ? null : AppRoutes.homePath;
      }
      final authenticated = session.asData?.value is Authenticated;
      if (isGate || (authenticated && isAuthPage)) {
        return destination ?? AppRoutes.homePath;
      }
      if (!authenticated && RouteAccessPolicy.requiresAuthentication(path)) {
        return RouteAccessPolicy.location(AppRoutes.loginPath, destination);
      }
      if (isAuthPage && state.uri.hasQuery && destination == null) {
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
