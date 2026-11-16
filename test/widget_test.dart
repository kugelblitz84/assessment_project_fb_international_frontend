import 'dart:async';

import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/presentation/pages/booking_confirmation_page.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/presentation/pages/booking_page.dart';
import 'package:assessment_project_fb_international_frontend/features/bookings/presentation/pages/booking_details_page.dart';
import 'package:assessment_project_fb_international_frontend/features/services/presentation/pages/service_details_page.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/session_fakes.dart';

void main() {
  late MemoryTokenStorage storage;
  late StubAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    storage = MemoryTokenStorage();
    repository = StubAuthRepository();
    container = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  Future<void> launch(WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );

  testWidgets('bootstrap, protected routes, route parameters and logout', (
    tester,
  ) async {
    storage.token = 'saved-token';
    repository.currentUserGate = Completer<UserEntity>();
    await launch(tester);
    await tester.pump();
    expect(find.text('Starting AutoCare...'), findsOneWidget);
    final router = container.read(routerProvider);
    router.goNamed(AppRoutes.profile);
    await tester.pump();
    expect(find.text('Log in to AutoCare'), findsNothing);
    repository.currentUserGate!.complete(testUser);
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Test Customer'), findsOneWidget);

    for (final auth in [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.bootstrap,
    ]) {
      router.goNamed(auth);
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Test Customer'), findsOneWidget);
    }
    const serviceId = 'wash & polish';
    const bookingId = 'booking 42';
    router.go(AppRoutes.serviceDetailsLocation(serviceId));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ServiceDetailsPage>(find.byType(ServiceDetailsPage))
          .serviceId,
      serviceId,
    );
    await tester.tap(find.text('Book this service'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BookingPage>(find.byType(BookingPage)).serviceId,
      serviceId,
    );
    router.go(AppRoutes.bookingConfirmationLocation(bookingId));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BookingConfirmationPage>(find.byType(BookingConfirmationPage))
          .bookingId,
      bookingId,
    );
    router.go(AppRoutes.bookingDetailsLocation(bookingId));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BookingDetailsPage>(find.byType(BookingDetailsPage))
          .bookingId,
      bookingId,
    );
    for (final route in [
      AppRoutes.myBookings,
      AppRoutes.editProfile,
      AppRoutes.assistant,
      AppRoutes.notFound,
    ]) {
      router.goNamed(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    router.go('/missing-page');
    await tester.pumpAndSettle();
    expect(find.text('Page not found'), findsOneWidget);
    router.goNamed(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.text('Email: customer@example.com'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(storage.token, isNull);
    expect(find.text('Log in to AutoCare'), findsOneWidget);
    for (final path in [
      AppRoutes.homePath,
      AppRoutes.profilePath,
      AppRoutes.editProfilePath,
      AppRoutes.myBookingsPath,
      AppRoutes.assistantPath,
      AppRoutes.serviceDetailsLocation(serviceId),
      AppRoutes.bookingLocation(serviceId),
      AppRoutes.bookingDetailsLocation(bookingId),
      AppRoutes.bookingConfirmationLocation(bookingId),
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text('Log in to AutoCare'), findsOneWidget, reason: path);
    }
    router.goNamed(AppRoutes.register);
    await tester.pumpAndSettle();
    expect(find.text('Create your AutoCare account'), findsOneWidget);
  });

  testWidgets(
    'bootstrap failure preserves the token and retry restores the session',
    (tester) async {
      storage.token = 'saved-token';
      repository.currentUserError = const AuthRequestException(
        'Server unavailable',
      );
      await launch(tester);
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(storage.token, 'saved-token');
      repository.currentUserError = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Test Customer'), findsOneWidget);
    },
  );

  testWidgets(
    'auth forms validate, show failures and authenticate through the session',
    (tester) async {
      await launch(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), testUser.email);
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      repository.authError = const InvalidCredentialsException();
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('The email or password is incorrect.'), findsOneWidget);
      expect(find.text('Starting AutoCare...'), findsNothing);
      repository.authError = null;
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Test Customer'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your name.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), testUser.name);
      await tester.enterText(find.byType(TextFormField).at(1), testUser.email);
      await tester.enterText(find.byType(TextFormField).at(2), 'password');
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Test Customer'), findsOneWidget);
    },
  );
}
