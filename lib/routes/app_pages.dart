import 'package:go_router/go_router.dart';

import '../core/navigation/presentation/not_found_page.dart';
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

final appPages = <RouteBase>[
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
    builder: (context, state) => HomePage(
      categoryId: state.uri.queryParameters['category'],
      resetFilters: state.uri.queryParameters['browse'] == 'all',
    ),
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
