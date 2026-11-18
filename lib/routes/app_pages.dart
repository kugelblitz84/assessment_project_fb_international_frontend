import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/app/shell/main_navigation_shell.dart';
import 'package:assessment_project_fb_international_frontend/app/shell/navigation_shell_scope.dart';
import 'package:assessment_project_fb_international_frontend/app/widgets/not_found_page.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/view/admin_appointment_details.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/view/admin_appointments_page.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/view/admin_categories_page.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/view/admin_category_form.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/view/admin_dashboard_page.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/view/admin_offer_form.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/view/admin_offers_page.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/payments/view/admin_payments_page.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/view/admin_service_form.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/view/admin_services_page.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_shell.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/view/ai_assistant_page.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/view/login_page.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/view/register_page.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/booking_confirmation_page.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/booking_page.dart';
import 'package:assessment_project_fb_international_frontend/features/bookings/view/booking_details_page.dart';
import 'package:assessment_project_fb_international_frontend/features/bookings/view/my_bookings_page.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/view/service_details_page.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/home_page.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/view/payment_page.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/view/edit_profile_page.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/view/profile_page.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

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
    ShellRoute(
      builder: (_, state, child) => AdminShell(
        key: ValueKey(identity),
        path: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(
          path: AppRoutes.adminPaymentsPath,
          builder: (_, _) => const AdminPaymentsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  AdminPaymentDetails(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.adminPath,
          builder: (_, _) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.adminCategoriesPath,
          builder: (_, _) => const AdminCategoriesPage(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, _) => const AdminCategoryFormPage(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (_, state) => AdminCategoryFormPage(
                key: ValueKey(state.pathParameters['id']),
                id: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        for (final package in [false, true])
          GoRoute(
            path: package
                ? AppRoutes.adminPackagesPath
                : AppRoutes.adminServicesPath,
            builder: (_, _) =>
                AdminServicesPage(key: ValueKey(package), packages: package),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => AdminServiceFormPage(
                  key: ValueKey('new-$package'),
                  package: package,
                ),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => AdminServiceFormPage(
                  key: ValueKey(state.pathParameters['id']),
                  id: state.pathParameters['id']!,
                  package: package,
                ),
              ),
            ],
          ),
        GoRoute(
          path: AppRoutes.adminOffersPath,
          builder: (_, _) => const AdminOffersPage(),
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const AdminOfferFormPage()),
            GoRoute(
              path: ':id/edit',
              builder: (_, state) => AdminOfferFormPage(
                key: ValueKey(state.pathParameters['id']),
                id: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.adminAppointmentsPath,
          builder: (_, state) => AdminAppointmentsPage(
            key: ValueKey(state.uri.queryParameters['status']),
            initialStatus: state.uri.queryParameters['status'],
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => AdminAppointmentDetails(
                key: ValueKey(state.pathParameters['id']),
                id: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    ),
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
                browseIntent: state.uri.queryParameters['intent'],
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
                      path: 'payment',
                      builder: (_, state) => PaymentPage(
                        key: ValueKey(identity),
                        appointmentId: state.pathParameters['bookingId']!,
                      ),
                    ),
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
