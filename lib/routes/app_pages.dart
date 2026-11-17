import 'package:go_router/go_router.dart';

import '../core/navigation/presentation/not_found_page.dart';
import '../core/session/presentation/bootstrap_errorpage.dart';
import '../core/session/presentation/bootstrap_view.dart';
import '../features/assistant/presentation/pages/ai_assistant_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/booking/presentation/pages/booking_confirmation_page.dart';
import '../features/booking/presentation/pages/booking_page.dart';
import '../features/bookings/presentation/pages/booking_details_page.dart';
import '../features/bookings/presentation/pages/my_bookings_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/services/presentation/pages/service_details_page.dart';
import 'app_routes.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';

final appPages = <RouteBase>[
  GoRoute(
    name: AppRoutes.onboarding,
    path: AppRoutes.onboardingPath,
    builder: (context, state) => const OnboardingPage(),
  ),
  GoRoute(
    name: AppRoutes.bootstrap,
    path: AppRoutes.bootstrapPath,
    builder: (context, state) => const BootstrapView(),
  ),
  GoRoute(
    name: AppRoutes.bootstrapError,
    path: AppRoutes.bootstrapErrorPath,
    builder: (context, state) => const BootstrapErrorPage(),
  ),
  GoRoute(
    name: AppRoutes.login,
    path: AppRoutes.loginPath,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    name: AppRoutes.register,
    path: AppRoutes.registerPath,
    builder: (context, state) => const RegisterPage(),
  ),
  GoRoute(
    name: AppRoutes.home,
    path: AppRoutes.homePath,
    builder: (context, state) => const HomePage(),
  ),
  GoRoute(
    name: AppRoutes.serviceDetails,
    path: AppRoutes.serviceDetailsPath,
    builder: (context, state) =>
        ServiceDetailsPage(serviceId: state.pathParameters['serviceId']!),
  ),
  GoRoute(
    name: AppRoutes.booking,
    path: AppRoutes.bookingPath,
    builder: (context, state) =>
        BookingPage(serviceId: state.pathParameters['serviceId']!),
  ),
  GoRoute(
    name: AppRoutes.bookingConfirmation,
    path: AppRoutes.bookingConfirmationPath,
    builder: (context, state) =>
        BookingConfirmationPage(bookingId: state.pathParameters['bookingId']!),
  ),
  GoRoute(
    name: AppRoutes.myBookings,
    path: AppRoutes.myBookingsPath,
    builder: (context, state) => const MyBookingsPage(),
  ),
  GoRoute(
    name: AppRoutes.bookingDetails,
    path: AppRoutes.bookingDetailsPath,
    builder: (context, state) =>
        BookingDetailsPage(bookingId: state.pathParameters['bookingId']!),
  ),
  GoRoute(
    name: AppRoutes.profile,
    path: AppRoutes.profilePath,
    builder: (context, state) => const ProfilePage(),
  ),
  GoRoute(
    name: AppRoutes.editProfile,
    path: AppRoutes.editProfilePath,
    builder: (context, state) => const EditProfilePage(),
  ),
  GoRoute(
    name: AppRoutes.assistant,
    path: AppRoutes.assistantPath,
    builder: (context, state) => const AiAssistantPage(),
  ),
  GoRoute(
    name: AppRoutes.notFound,
    path: AppRoutes.notFoundPath,
    builder: (context, state) => const NotFoundPage(),
  ),
];
