import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/navigation/presentation/main_navigation_shell.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/controller/assistant_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/view/ai_assistant_page.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/service/booking_service.dart';
import 'package:assessment_project_fb_international_frontend/features/bookings/controller/my_bookings_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/bookings/view/my_bookings_page.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/home_page.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/view/profile_page.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/model/availability_model.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/service/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/demo_container.dart';

Future<ProviderContainer> launch(
  WidgetTester tester, {
  ProviderContainer? provided,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final container = provided ?? demoContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> selectTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'desktop secondary headers restore branch history from a root overlay',
    (tester) async {
      final container = await launch(tester);
      tester.view.physicalSize = const Size(1440, 900);
      final router = container.read(routerProvider);
      router.go('/profile/edit');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Unsubmitted profile',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Bookings'));
      await tester.pumpAndSettle();
      router.go('/bookings/demo-driver-AC1042');
      await tester.pumpAndSettle();
      router.push('/services/exterior-wash');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Profile'));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.state.uri.path, '/profile/edit');
      expect(
        find.widgetWithText(TextFormField, 'Unsubmitted profile'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Bookings'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.state.uri.path,
        '/bookings/demo-driver-AC1042',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'app resume revalidates a valid review selection and skips covered booking pages',
    (tester) async {
      late CountingAvailability service;
      final container = await launch(
        tester,
        provided: demoContainer(
          bookingFactory: (dio, demo) =>
              service = CountingAvailability(dio, demo),
        ),
      );
      final router = container.read(routerProvider);
      router.go('/services/exterior-wash/book');
      await tester.pumpAndSettle();
      final provider = bookingControllerProvider('exterior-wash');
      final controller = container.read(provider.notifier);
      controller.selectDate(DemoWorkshop.today.add(const Duration(days: 3)));
      await tester.pumpAndSettle();
      final slot = container
          .read(provider)
          .requireValue
          .availability!
          .slots
          .firstWhere((slot) => slot.available);
      controller.selectSlot(slot.id);
      controller.review();
      await tester.pumpAndSettle();
      var calls = service.calls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(service.calls, calls + 1);
      expect(container.read(provider).requireValue.step, BookingStep.review);
      expect(container.read(provider).requireValue.slotId, slot.id);
      service.failNext = true;
      controller.refreshAvailability();
      await tester.pumpAndSettle();
      expect(
        container.read(provider).requireValue.availabilityError,
        isNotNull,
      );
      final retry = find.text('Refresh available times');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(container.read(provider).requireValue.canContinue, isTrue);
      expect(container.read(provider).requireValue.step, BookingStep.review);
      router.push('/services/oil-change');
      await tester.pumpAndSettle();
      calls = service.calls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(service.calls, calls);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'assistant service and repeated browse actions preserve navigation and apply filters',
    (tester) async {
      final container = await launch(tester);
      final router = container.read(routerProvider);
      await selectTab(tester, 'AI Assistant');
      container.read(assistantControllerProvider.notifier).send('wash');
      await tester.pumpAndSettle();
      final serviceAction = find.text('View service →').first;
      await tester.ensureVisible(serviceAction);
      await tester.tap(serviceAction);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.state.uri.path, '/services/exterior-wash');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 2; attempt++) {
        final browseAction = find.text('Browse services');
        await tester.ensureVisible(browseAction);
        await tester.tap(browseAction);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/home');
        expect(
          router.routeInformationProvider.value.uri.queryParameters['browse'],
          'all',
        );
        expect(container.read(homeControllerProvider).filtered, isFalse);
        container.read(homeControllerProvider.notifier).search('oil');
        await tester.pumpAndSettle();
        await selectTab(tester, 'AI Assistant');
      }
      expect(
        container.read(assistantControllerProvider).messages,
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'logout while a root overlay covers the assistant discards its private draft',
    (tester) async {
      final container = await launch(tester);
      final router = container.read(routerProvider);
      await selectTab(tester, 'AI Assistant');
      await tester.enterText(find.byType(TextField), 'Covered private draft');
      router.push('/services/exterior-wash');
      await tester.pumpAndSettle();
      await container.read(sessionProvider.notifier).logout();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/assistant');
      expect(
        find.widgetWithText(TextField, 'Covered private draft'),
        findsNothing,
      );
      expect(container.read(assistantControllerProvider).messages, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'branches mount lazily, stay mounted, and mute inactive tickers',
    (tester) async {
      final container = await launch(tester);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(MyBookingsPage, skipOffstage: false), findsNothing);
      expect(find.byType(AiAssistantPage, skipOffstage: false), findsNothing);
      expect(find.byType(ProfilePage, skipOffstage: false), findsNothing);
      expect(container.exists(assistantControllerProvider), isFalse);
      expect(container.exists(myBookingsTabProvider), isFalse);

      final homeState = tester.state(find.byType(HomePage));
      await selectTab(tester, 'AI Assistant');
      final assistantState = tester.state(find.byType(AiAssistantPage));
      await selectTab(tester, 'Explore');
      expect(tester.state(find.byType(HomePage)), same(homeState));
      final assistant = find.byType(AiAssistantPage, skipOffstage: false);
      expect(tester.state(assistant), same(assistantState));
      expect(
        TickerMode.getValuesNotifier(tester.element(assistant)).value.enabled,
        isFalse,
      );
      await selectTab(tester, 'Bookings');
      await selectTab(tester, 'Profile');
      expect(find.byType(HomePage, skipOffstage: false), findsOneWidget);
      expect(find.byType(MyBookingsPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(AiAssistantPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tab switching and reselection preserve filters, scroll, chat, and drafts',
    (tester) async {
      final container = await launch(tester);
      final router = container.read(routerProvider);
      router.go('/home?category=cleaning&browse=all');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'wash');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(HomePage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final offset = scroll.position.pixels;
      expect(offset, greaterThan(0));
      await selectTab(tester, 'AI Assistant');
      await container.read(assistantControllerProvider.notifier).send('wash');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Unsent private question');
      await selectTab(tester, 'Bookings');
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      await selectTab(tester, 'Explore');
      expect(scroll.position.pixels, closeTo(offset, .1));
      expect(container.read(homeControllerProvider).query, 'wash');
      expect(container.read(homeControllerProvider).categoryId, 'cleaning');
      await selectTab(tester, 'Explore');
      expect(scroll.position.pixels, closeTo(offset, .1));
      expect(container.read(homeControllerProvider).query, 'wash');
      await selectTab(tester, 'AI Assistant');
      expect(
        find.widgetWithText(TextField, 'Unsent private question'),
        findsOneWidget,
      );
      expect(
        container.read(assistantControllerProvider).messages,
        hasLength(2),
      );
      await selectTab(tester, 'Bookings');
      expect(container.read(myBookingsTabProvider), BookingsTab.previous);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'branch locations restore independently and secondary screens support back',
    (tester) async {
      final container = await launch(tester);
      final router = container.read(routerProvider);
      router.go('/bookings/demo-driver-AC1042?source=history');
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      var shell = tester
          .widget<MainNavigationShell>(
            find.byType(MainNavigationShell, skipOffstage: false),
          )
          .navigationShell;
      shell.goBranch(3);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      shell = tester
          .widget<MainNavigationShell>(find.byType(MainNavigationShell))
          .navigationShell;
      shell.goBranch(1);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/bookings/demo-driver-AC1042?source=history',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/bookings');
      expect(find.byType(NavigationBar), findsOneWidget);
      await selectTab(tester, 'AI Assistant');
      final assistant = tester.state(find.byType(AiAssistantPage));
      router.push('/services/exterior-wash');
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/assistant');
      expect(tester.state(find.byType(AiAssistantPage)), same(assistant));
    },
  );

  testWidgets(
    'profile updates preserve branches; logout discards private local state',
    (tester) async {
      final container = await launch(tester);
      final router = container.read(routerProvider);
      await selectTab(tester, 'AI Assistant');
      container
          .read(assistantControllerProvider.notifier)
          .send('private wash question');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Private draft');
      final assistant = tester.state(find.byType(AiAssistantPage));
      container
          .read(sessionProvider.notifier)
          .updateUser(
            const UserEntity(
              id: 'demo-driver',
              name: 'Updated Driver',
              email: 'updated@example.com',
            ),
          );
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(AiAssistantPage)), same(assistant));
      expect(find.widgetWithText(TextField, 'Private draft'), findsOneWidget);
      expect(
        container.read(assistantControllerProvider).messages,
        hasLength(2),
      );
      await selectTab(tester, 'Profile');
      await container.read(sessionProvider.notifier).logout();
      await tester.pumpAndSettle();
      expect(container.read(routerProvider), same(router));
      expect(find.byType(AiAssistantPage, skipOffstage: false), findsNothing);
      expect(container.read(assistantControllerProvider).messages, isEmpty);
      final login = container
          .read(sessionProvider.notifier)
          .login(email: 'other@example.com', password: 'demo');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await login;
      router.go('/assistant');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Private draft'), findsNothing);
      expect(container.read(assistantControllerProvider).messages, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

class CountingAvailability extends BookingService {
  CountingAvailability(super.dio, super.demo);
  int calls = 0;
  bool failNext = false;
  @override
  Future<AvailabilityModel> getAvailability(String serviceId, DateTime date) {
    calls++;
    if (failNext) {
      failNext = false;
      return Future.error(StateError('temporary availability failure'));
    }
    return super.getAvailability(serviceId, date);
  }
}
