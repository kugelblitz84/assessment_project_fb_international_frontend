import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/service/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/demo_container.dart';

void main() {
  testWidgets(
    'guest signs in, reviews a booking, then cancels the pending request',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final container = demoContainer(authenticated: false);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/services/exterior-wash/book');
      await tester.pumpAndSettle();
      expect(find.text('Log in to AutoCare'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'driver@autocare.demo',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'demo');
      await tester.ensureVisible(find.text('Log in'));
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/services/exterior-wash/book',
      );
      container
          .read(bookingControllerProvider('exterior-wash').notifier)
          .selectDate(DemoWorkshop.today.add(const Duration(days: 1)));
      await tester.pumpAndSettle();
      final slot = find
          .byWidgetPredicate(
            (widget) => widget is ChoiceChip && widget.onSelected != null,
          )
          .first;
      await tester.ensureVisible(slot);
      await tester.tap(slot);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to review'));
      await tester.pumpAndSettle();
      expect(find.text('One last look'), findsOneWidget);
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();
      expect(find.text('Booking request received'), findsOneWidget);
      await tester.ensureVisible(find.text('View my bookings'));
      await tester.tap(find.text('View my bookings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View details').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('View details').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cancel appointment'));
      await tester.tap(find.text('Cancel appointment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel appointment'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel appointment'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Cancel appointment'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
