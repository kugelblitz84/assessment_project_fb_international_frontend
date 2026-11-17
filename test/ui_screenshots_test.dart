import 'dart:io';
import 'dart:ui' as ui;
import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/controller/assistant_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/service/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/demo_container.dart';

/// Opt-in visual review artifacts; regular tests do not write screenshots.
void main() {
  const capture = bool.fromEnvironment('CAPTURE_UI');
  for (final width in [390.0, 1440.0]) {
    testWidgets('capture UI at $width', (tester) async {
      const font = String.fromEnvironment('SCREENSHOT_FONT');
      if (font.isNotEmpty) {
        final loader = FontLoader('Roboto')
          ..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          );
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, width < 900 ? 844 : 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      final container = demoContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: boundaryKey, child: const App()),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      final prefix = width < 900 ? 'mobile' : 'desktop';
      Future<void> save(String name) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = await Directory(
            'build/ui_screenshots',
          ).create(recursive: true);
          await File(
            '${directory.path}/$prefix-$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await save('explore');
      await tester.ensureVisible(find.text('Care for every journey'));
      await save('catalogue');
      for (final item in [
        ('service', '/services/exterior-wash'),
        ('bookings', '/bookings'),
        ('booking-details', '/bookings/demo-driver-AC1042'),
        ('acknowledgement', '/bookings/demo-driver-AC1042/confirmation'),
        ('profile', '/profile'),
        ('edit-profile', '/profile/edit'),
        ('assistant', '/assistant'),
      ]) {
        router.go(item.$2);
        await tester.pumpAndSettle();
        await save(item.$1);
      }
      container
          .read(assistantControllerProvider.notifier)
          .send('What is included in a full car wash?');
      await tester.pumpAndSettle();
      await save('assistant-recommendations');
      router.go('/services/exterior-wash/book');
      await tester.pumpAndSettle();
      final controller = container.read(
        bookingControllerProvider('exterior-wash').notifier,
      );
      controller.selectDate(DemoWorkshop.today.add(const Duration(days: 1)));
      await tester.pumpAndSettle();
      await save('schedule');
      final draft = container
          .read(bookingControllerProvider('exterior-wash'))
          .requireValue;
      controller.selectSlot(
        draft.availability!.slots.firstWhere((s) => s.available).id,
      );
      controller.review();
      await save('review');
      await container.read(sessionProvider.notifier).logout();
      for (final route in ['login', 'register', 'profile']) {
        router.go('/$route');
        await tester.pumpAndSettle();
        await save(route == 'profile' ? 'guest-profile' : route);
      }
    }, skip: !capture);
  }
}
