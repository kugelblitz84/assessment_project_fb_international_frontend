import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_overrides.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/booking_page.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';
import 'package:assessment_project_fb_international_frontend/routes/route_access_policy.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';

import 'support/session_fakes.dart';

void main() {
  late MemoryTokenStorage storage;
  late StubAuthRepository repository;
  late ProviderContainer container;

  ProviderContainer createContainer() => ProviderContainer.test(
    overrides: [
      ...demoServiceOverrides(),
      demoModeProvider.overrideWithValue(true),
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(repository),
    ],
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = MemoryTokenStorage();
    repository = StubAuthRepository();
    container = createContainer();
  });

  Future<void> launch(WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );

  testWidgets(
    'authenticated startup deep link stays unmounted until restoration completes; retry and invalidation remain guarded',
    (tester) async {
      storage.token = 'saved';
      repository.currentUserGate = Completer<UserEntity>();
      tester.binding.platformDispatcher.defaultRouteNameTestValue =
          '/services/123/book?slot=morning';
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      await launch(tester);
      await tester.pump();
      final router = container.read(routerProvider);
      expect(find.text('Starting AutoCare...'), findsOneWidget);
      expect(find.byType(BookingPage), findsNothing);
      repository.currentUserGate!.complete(testUser);
      await tester.pumpAndSettle();
      expect(find.byType(BookingPage), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.queryParameters['slot'],
        'morning',
      );
      repository.currentUserGate = Completer<UserEntity>();
      container.invalidate(sessionProvider);
      await tester.pump();
      expect(find.byType(BookingPage), findsNothing);
      expect(find.text('Starting AutoCare...'), findsOneWidget);
      repository.currentUserGate!.complete(testUser);
      await tester.pumpAndSettle();
      expect(container.read(routerProvider), same(router));
      expect(find.byType(BookingPage), findsOneWidget);
      container.read(tokenRefreshCoordinatorProvider).onInvalidSession!();
      await tester.pumpAndSettle();
      expect(find.text('Log in to AutoCare'), findsOneWidget);
      expect(find.byType(BookingPage), findsNothing);
    },
  );

  testWidgets(
    'ordinary login goes Home and authenticated users cannot revisit auth pages',
    (tester) async {
      await launch(tester);
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/login');
      await tester.pumpAndSettle();
      await container
          .read(sessionProvider.notifier)
          .login(email: testUser.email, password: 'password');
      await tester.pumpAndSettle();
      for (final path in ['/login', '/register']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/home');
      }
      for (final path in [
        '/bookings',
        '/bookings/42',
        '/bookings/42/confirmation',
        '/profile/edit',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, path);
      }
      router.go('/missing-page');
      await tester.pumpAndSettle();
      expect(find.text('Page not found'), findsOneWidget);
    },
  );

  testWidgets(
    'guests browse all public routes and protected deep links require login',
    (tester) async {
      await launch(tester);
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      for (final path in [
        '/home',
        '/services/wash%20%26%20polish',
        '/assistant',
        '/profile',
        '/missing-page',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.text('Log in to AutoCare'), findsNothing, reason: path);
        expect(tester.takeException(), isNull);
      }
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Edit profile'), findsNothing);
      expect(find.text('Log out'), findsNothing);
      for (final path in [
        '/services/wash/book',
        '/bookings',
        '/bookings/42',
        '/bookings/42/confirmation',
        '/profile/edit',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.text('Log in to AutoCare'), findsOneWidget, reason: path);
        expect(
          router.routeInformationProvider.value.uri.queryParameters['redirect'],
          path,
        );
      }
    },
  );

  for (final register in [false, true]) {
    testWidgets(
      'booking intent survives startup and auth switching and ${register ? 'registration' : 'login'}',
      (tester) async {
        storage.token = 'saved';
        repository.currentUserGate = Completer<UserEntity>();
        // Hold restoration while a protected deep link is requested.
        await launch(tester);
        await tester.pump();
        final router = container.read(routerProvider);
        const target = '/services/wash%20%26%20polish/book?slot=morning';
        router.go(target);
        await tester.pump();
        expect(find.text('Starting AutoCare...'), findsOneWidget);
        expect(find.byType(BookingPage), findsNothing);
        expect(container.read(routerProvider), same(router));
        repository.currentUserGate!.completeError(
          const InvalidSessionException(),
        );
        await tester.pumpAndSettle();
        expect(find.text('Log in to AutoCare'), findsOneWidget);
        await tester.tap(find.text('Create an account'));
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.queryParameters['redirect'],
          target,
        );
        await tester.ensureVisible(
          find.text('Already have an account? Log in'),
        );
        await tester.tap(find.text('Already have an account? Log in'));
        await tester.pumpAndSettle();
        if (register) {
          await tester.tap(find.text('Create an account'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField).at(0),
            testUser.name,
          );
        }
        final offset = register ? 1 : 0;
        await tester.enterText(
          find.byType(TextFormField).at(offset),
          testUser.email,
        );
        await tester.enterText(
          find.byType(TextFormField).at(offset + 1),
          'password',
        );
        await tester.ensureVisible(find.text(register ? 'Register' : 'Log in'));
        await tester.tap(find.text(register ? 'Register' : 'Log in'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<BookingPage>(find.byType(BookingPage)).serviceId,
          'wash & polish',
        );
        expect(router.routeInformationProvider.value.uri.toString(), target);
      },
    );
  }

  testWidgets('logout clears user state and displays guest Profile', (
    tester,
  ) async {
    storage.token = 'saved';
    await launch(tester);
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    router.goNamed(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.text('customer@example.com'), findsOneWidget);
    await tester.ensureVisible(find.text('Log out'));
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(storage.token, isNull);
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets(
    'failed restoration retains credentials and allows guest browsing and retry',
    (tester) async {
      storage.token = 'saved';
      repository.currentUserError = const AuthRequestException('Offline');
      await launch(tester);
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
      expect(storage.token, 'saved');
      final router = container.read(routerProvider);
      router.go('/bookings/42');
      await tester.pumpAndSettle();
      expect(find.text('Log in to AutoCare'), findsOneWidget);
      router.go('/profile');
      await tester.pumpAndSettle();
      repository.currentUserError = null;
      await tester.ensureVisible(find.text('Retry session restoration'));
      await tester.tap(find.text('Retry session restoration'));
      await tester.pumpAndSettle();
      expect(find.text('customer@example.com'), findsOneWidget);
    },
  );

  testWidgets(
    'invalid auth redirects are removed and successful login goes Home',
    (tester) async {
      await launch(tester);
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      for (final destination in [
        'https://evil.test/home',
        '//evil.test/home',
        '/login',
        '/register',
        '/',
        '/profile',
        '/unknown',
        '/services/%2F/book',
      ]) {
        router.go(
          Uri(
            path: '/login',
            queryParameters: {'redirect': destination},
          ).toString(),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.toString(), '/login');
      }
      await container
          .read(sessionProvider.notifier)
          .login(email: testUser.email, password: 'password');
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Test Customer'), findsOneWidget);
    },
  );

  testWidgets(
    'auth forms validate and display failures without leaving the form',
    (tester) async {
      await launch(tester);
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/login');
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
    },
  );

  test(
    'redirect validation rejects external, gate, malformed and traversal destinations',
    () {
      for (final value in [
        'https://evil.test/home',
        '//evil.test/home',
        r'/\evil.test',
        '/login?redirect=/home',
        '/register',
        '/',
        '/home',
        '/profile',
        '/missing',
        '/services/%2f/book',
        '/services/%5c/book',
        '/services/%00/book',
        '/services/%252f/book',
        '/services/%FF/book',
        '/services/../book',
        '/services/../services/123/book',
        '/services/%2e%2e/services/123/book',
        '/services/123',
        '/assistant',
        '/home#fragment',
        'home',
        '/home\n',
      ]) {
        expect(
          RouteAccessPolicy.validateDestination(value),
          isNull,
          reason: value,
        );
      }
      expect(
        RouteAccessPolicy.validateDestination(
          '/services/wash%20%26%20polish/book?slot=morning',
        ),
        '/services/wash%20%26%20polish/book?slot=morning',
      );
      expect(
        RouteAccessPolicy.redirectDestination(Uri.parse('/login?redirect=%FF')),
        isNull,
      );
      expect(
        RouteAccessPolicy.redirectDestination(
          Uri.parse('/login?redirect=/home&redirect=/profile'),
        ),
        isNull,
      );
    },
  );
}
