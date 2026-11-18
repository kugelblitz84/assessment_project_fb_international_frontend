import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/controller/assistant_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';

import 'support/demo_container.dart';

void main() {
  for (final width in [
    320.0,
    375.0,
    390.0,
    430.0,
    768.0,
    900.0,
    1024.0,
    1280.0,
    1440.0,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('all pages fit width $width at text scale $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, width < 900 ? 812 : 900);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = demoContainer();
        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pumpAndSettle();
        final router = container.read(routerProvider);
        for (final path in [
          '/home',
          '/services/exterior-wash',
          '/services/exterior-wash/book',
          '/bookings',
          '/bookings/demo-driver-AC1042',
          '/bookings/demo-driver-AC1042/confirmation',
          '/profile',
          '/profile/edit',
          '/assistant',
          '/not-found',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$path at $width / $scale',
          );
        }
        router.go('/assistant');
        await tester.pumpAndSettle();
        container
            .read(assistantControllerProvider.notifier)
            .send('What is included in a full car wash?');
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'chat with recommendations',
        );
        // Keyboard-open composition must leave room for the composer and scroll.
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'keyboard open');
        tester.view.resetViewInsets();
        await container.read(sessionProvider.notifier).logout();
        for (final path in ['/login', '/register', '/profile']) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$path at $width / $scale',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
    'resize preserves search, booking selection, form input, and chat draft',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = demoContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      final sameRouter = router;
      container.read(homeControllerProvider.notifier).search('oil');
      for (final width in [375.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        expect(container.read(homeControllerProvider).query, 'oil');
        expect(find.widgetWithText(TextField, 'oil'), findsOneWidget);
      }
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
          .firstWhere((s) => s.available);
      controller.selectSlot(slot.id);
      controller.review();
      for (final width in [375.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        expect(container.read(provider).requireValue.slotId, slot.id);
        expect(container.read(provider).requireValue.step, BookingStep.review);
        expect(tester.takeException(), isNull);
      }
      router.go('/profile/edit');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Unsubmitted name',
      );
      tester.view.physicalSize = const Size(375, 900);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Unsubmitted name'),
        findsOneWidget,
      );
      router.go('/assistant');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Unsent question');
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Unsent question'), findsOneWidget);
      expect(container.read(routerProvider), same(sameRouter));
      expect(tester.takeException(), isNull);
    },
  );
}
