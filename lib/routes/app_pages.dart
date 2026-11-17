import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/presentation/not_found_page.dart';
import '../core/session/application/session_identity_provider.dart';
import '../core/navigation/presentation/main_navigation_shell.dart';
import '../core/navigation/presentation/navigation_shell_scope.dart';
import '../features/assistant/view/ai_assistant_page.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/register_page.dart';
import '../features/booking/view/booking_confirmation_page.dart';
import '../features/booking/view/booking_page.dart';
import '../features/bookings/view/booking_details_page.dart';
import '../features/bookings/view/my_bookings_page.dart';
import '../features/home/view/home_page.dart';
import '../features/profile/view/edit_profile_page.dart';
import '../features/profile/view/profile_page.dart';
import '../features/services/view/service_details_page.dart';
import 'app_routes.dart';

/// New shell/branch keys discard mounted private state on ownership changes.
List<RouteBase> createAppPages(
  GlobalKey<NavigatorState> rootNavigatorKey,
  SessionIdentity identity,
) {
  final shellKey = GlobalKey<StatefulNavigationShellState>(
    debugLabel: 'main-shell',
  );
  Widget rootScreen(Widget child) =>
      NavigationShellScope(shellKey: shellKey, child: child);
  return [
    GoRoute(
      name: AppRoutes.login,
      path: AppRoutes.loginPath,
      builder: (_, _) => const LoginPage(),
    ),
    GoRoute(
      name: AppRoutes.register,
      path: AppRoutes.registerPath,
      builder: (_, _) => const RegisterPage(),
    ),
    GoRoute(
      name: AppRoutes.serviceDetails,
      path: AppRoutes.serviceDetailsPath,
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, state) => rootScreen(
        ServiceDetailsPage(serviceId: state.pathParameters['serviceId']!),
      ),
      routes: [
        GoRoute(
          name: AppRoutes.booking,
          path: 'book',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, state) => rootScreen(
            BookingPage(
              key: ValueKey(identity),
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      key: shellKey,
      builder: (context, state, shell) => MainNavigationShell(
        navigationShell: shell,
        showNavigation: const [
          AppRoutes.homePath,
          AppRoutes.myBookingsPath,
          AppRoutes.assistantPath,
          AppRoutes.profilePath,
        ].contains(state.uri.path),
      ),
      branches: [
        StatefulShellBranch(
          preload: false,
          routes: [
            GoRoute(
              name: AppRoutes.home,
              path: AppRoutes.homePath,
              builder: (_, state) => HomePage(
                categoryId: state.uri.queryParameters['category'],
                resetFilters: state.uri.queryParameters['browse'] == 'all',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          preload: false,
          routes: [
            GoRoute(
              name: AppRoutes.myBookings,
              path: AppRoutes.myBookingsPath,
              builder: (_, _) => const MyBookingsPage(),
              routes: [
                GoRoute(
                  name: AppRoutes.bookingDetails,
                  path: ':bookingId',
                  builder: (_, state) => BookingDetailsPage(
                    key: ValueKey(identity),
                    bookingId: state.pathParameters['bookingId']!,
                  ),
                  routes: [
                    GoRoute(
                      name: AppRoutes.bookingConfirmation,
                      path: 'confirmation',
                      builder: (_, state) => BookingConfirmationPage(
                        key: ValueKey(identity),
                        bookingId: state.pathParameters['bookingId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          preload: false,
          routes: [
            GoRoute(
              name: AppRoutes.assistant,
              path: AppRoutes.assistantPath,
              builder: (_, _) => const AiAssistantPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          preload: false,
          routes: [
            GoRoute(
              name: AppRoutes.profile,
              path: AppRoutes.profilePath,
              builder: (_, _) => const ProfilePage(),
              routes: [
                GoRoute(
                  name: AppRoutes.editProfile,
                  path: 'edit',
                  builder: (_, _) => EditProfilePage(key: ValueKey(identity)),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      name: AppRoutes.notFound,
      path: AppRoutes.notFoundPath,
      builder: (_, _) => const NotFoundPage(),
    ),
  ];
}
