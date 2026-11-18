import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';

import 'support/admin_fakes.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'capture admin UI at $width',
      (tester) async {
        const font = String.fromEnvironment('SCREENSHOT_FONT');
        if (font.isNotEmpty) {
          await (FontLoader('Roboto')..addFont(
                Future.value(
                  ByteData.sublistView(File(font).readAsBytesSync()),
                ),
              ))
              .load();
        }
        await (FontLoader('RobotoCondensed')
              ..addFont(
                rootBundle.load('assets/fonts/RobotoCondensed-Regular.ttf'),
              )
              ..addFont(
                rootBundle.load('assets/fonts/RobotoCondensed-Bold.ttf'),
              ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = adminContainer(adapter: AdminAdapter());
        await container.read(sessionProvider.future);
        final key = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(key: key, child: const App()),
          ),
        );
        for (final (label, path) in [
          ('dashboard', '/admin'),
          ('categories', '/admin/categories'),
          ('service-form', '/admin/services/$serviceId/edit'),
          ('package-form', '/admin/packages/$packageId/edit'),
          ('appointments', '/admin/appointments'),
        ]) {
          container.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final snapshot = await boundary.toImage();
            final bytes = await snapshot.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = await Directory(
              'build/admin_screenshots',
            ).create(recursive: true);
            await File(
              '${directory.path}/${width.toInt()}-$label.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            snapshot.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
      skip: !const bool.fromEnvironment('CAPTURE_ADMIN_UI'),
    );
  }
}
