import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_theme.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_resume_listener.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/model/auth_form_state.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/view/widgets/auth_form.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/booking_page.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/view/widgets/profile_edit_form.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/demo_container.dart';

Widget formHost(Widget child) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> launch(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final container = demoContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return container;
}

void resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

Future<void> enterBookingDate(WidgetTester tester, DateTime date) async {
  await tapVisible(tester, find.byType(OutlinedButton).first);
  expect(find.byType(DatePickerDialog), findsOneWidget);
  await tapVisible(tester, find.byIcon(Icons.edit_outlined));
  final dialogContext = tester.element(find.byType(DatePickerDialog));
  final dateText = MaterialLocalizations.of(
    dialogContext,
  ).formatCompactDate(date);
  await tester.enterText(find.byType(TextField).last, dateText);
}

void main() {
  for (final mode in AuthFormMode.values) {
    testWidgets(
      '$mode form preserves validation, visibility, and credentials',
      (tester) async {
        ({String? name, String email, String password})? submitted;
        var submissions = 0;
        Widget form({bool busy = false, String? error}) => formHost(
          AuthForm(
            key: ValueKey(mode),
            mode: mode,
            submitting: busy,
            error: error,
            onSwitchMode: busy ? null : () {},
            onSubmit: ({required email, required password, name}) {
              submissions++;
              submitted = (name: name, email: email, password: password);
            },
          ),
        );
        await tester.pumpWidget(form());
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        final register = mode == AuthFormMode.register;
        final submit = find.text(register ? 'Register' : 'Log in');
        await tapVisible(tester, submit);
        expect(submissions, 0);
        expect(find.text('Enter a valid email address.'), findsOneWidget);
        expect(find.text('Enter your password.'), findsOneWidget);
        if (register) {
          expect(find.text('Enter your name.'), findsOneWidget);
          await tester.enterText(fields.first, 'New Driver');
        }
        await tester.enterText(
          fields.at(register ? 1 : 0),
          'driver@example.com',
        );
        await tester.enterText(fields.last, 'local-secret');
        await tapVisible(tester, find.byTooltip('Show password'));
        final passwordInput = find.descendant(
          of: fields.last,
          matching: find.byType(TextField),
        );
        expect(tester.widget<TextField>(passwordInput).obscureText, isFalse);

        await tester.pumpWidget(form(busy: true));
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.visibility_off_outlined),
              )
              .onPressed,
          isNull,
        );
        for (final field in tester.widgetList<TextFormField>(fields)) {
          expect(field.enabled, isFalse);
        }
        expect(submissions, 0);

        await tester.pumpWidget(form(error: 'Please try again.'));
        await tester.pumpAndSettle();
        expect(find.text('Please try again.'), findsOneWidget);
        expect(
          tester.widget<TextFormField>(fields.last).controller!.text,
          'local-secret',
        );
        await tapVisible(tester, find.byTooltip('Hide password'));
        expect(tester.widget<TextField>(passwordInput).obscureText, isTrue);
        await tester.showKeyboard(fields.last);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(submissions, 1);
        expect(submitted, (
          name: register ? 'New Driver' : null,
          email: 'driver@example.com',
          password: 'local-secret',
        ));

        final controllers = tester
            .widgetList<TextFormField>(fields)
            .map((field) => field.controller!)
            .toList();
        await tester.pumpWidget(const SizedBox.shrink());
        for (final controller in controllers) {
          expect(() => controller.addListener(() {}), throwsFlutterError);
        }
      },
    );
  }

  testWidgets(
    'profile form keeps a draft through rebuilds and validates saves',
    (tester) async {
      final submissions = <(String, String)>[];
      Widget form(String initialName, {bool saving = false}) => formHost(
        ProfileEditForm(
          initialName: initialName,
          initialEmail: 'driver@example.com',
          saving: saving,
          onSubmit: (payload) => submissions.add((payload.name, payload.email)),
        ),
      );
      await tester.pumpWidget(form('Driver'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '');
      await tester.enterText(fields.last, 'invalid');
      await tapVisible(tester, find.text('Save changes'));
      expect(find.text('Enter your name.'), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(submissions, isEmpty);

      await tester.enterText(fields.first, '  Unsaved Driver  ');
      await tester.enterText(fields.last, '  new@example.com  ');
      await tester.pumpWidget(form('Server update', saving: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<TextFormField>(fields.first).enabled, isFalse);
      expect(
        tester.widget<TextFormField>(fields.first).controller!.text,
        '  Unsaved Driver  ',
      );
      await tester.pumpWidget(form('Another update'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save changes'));
      expect(submissions, [('Unsaved Driver', 'new@example.com')]);
      final controllers = tester
          .widgetList<TextFormField>(fields)
          .map((field) => field.controller!)
          .toList();
      await tester.pumpWidget(const SizedBox.shrink());
      for (final controller in controllers) {
        expect(() => controller.addListener(() {}), throwsFlutterError);
      }
    },
  );

  testWidgets('profile drafts survive same-user updates and reset on login', (
    tester,
  ) async {
    final container = await launch(tester);
    final router = container.read(routerProvider);
    router.go('/profile/edit');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Private draft');
    container
        .read(sessionProvider.notifier)
        .updateUser(
          const UserEntity(
            id: 'demo-driver',
            name: 'Updated Driver',
            email: 'driver@autocare.demo',
          ),
        );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Private draft'), findsOneWidget);

    await container.read(sessionProvider.notifier).logout();
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => container
          .read(sessionProvider.notifier)
          .register(
            name: 'Another Driver',
            email: 'another@example.com',
            password: 'secret',
          ),
    );
    await tester.pumpAndSettle();
    router.go('/profile/edit');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Private draft'), findsNothing);
    expect(
      find.widgetWithText(TextFormField, 'Another Driver'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'another@example.com'),
      findsOneWidget,
    );
  });

  testWidgets('resume listener follows updated callbacks and unregisters', (
    tester,
  ) async {
    var firstCalls = 0;
    var nextCalls = 0;
    Widget host(VoidCallback callback, {bool enabled = true}) => MaterialApp(
      home: TickerMode(
        enabled: enabled,
        child: AppResumeListener(onResume: callback, child: const SizedBox()),
      ),
    );
    await tester.pumpWidget(host(() => firstCalls++));
    resume(tester);
    expect(firstCalls, 1);
    await tester.pumpWidget(host(() => nextCalls++));
    resume(tester);
    expect(firstCalls, 1);
    expect(nextCalls, 1);
    await tester.pumpWidget(host(() => nextCalls++, enabled: false));
    resume(tester);
    expect(nextCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    resume(tester);
    expect(nextCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date-picker result cannot update a replaced booking draft', (
    tester,
  ) async {
    final container = await launch(tester);
    container.read(routerProvider).go('/services/exterior-wash/book');
    await tester.pumpAndSettle();
    final provider = bookingControllerProvider('exterior-wash');
    final initialDate = container.read(provider).requireValue.date;
    await enterBookingDate(tester, initialDate.add(const Duration(days: 3)));
    container.invalidate(provider);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('OK'));
    expect(container.read(provider).requireValue.date, initialDate);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date-picker result updates the active booking draft', (
    tester,
  ) async {
    final container = await launch(tester);
    container.read(routerProvider).go('/services/exterior-wash/book');
    await tester.pumpAndSettle();
    final provider = bookingControllerProvider('exterior-wash');
    final date = container
        .read(provider)
        .requireValue
        .date
        .add(const Duration(days: 3));
    await enterBookingDate(tester, date);
    await tapVisible(tester, find.text('OK'));
    expect(container.read(provider).requireValue.date, date);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mounted date picker cannot edit a new session', (tester) async {
    final container = demoContainer();
    await container.read(sessionProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.light,
            home: const BookingPage(serviceId: 'exterior-wash'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final provider = bookingControllerProvider('exterior-wash');
    final initialDate = container.read(provider).requireValue.date;
    await enterBookingDate(tester, initialDate.add(const Duration(days: 3)));
    await container.read(sessionProvider.notifier).logout();
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => container
          .read(sessionProvider.notifier)
          .register(
            name: 'Another Driver',
            email: 'another@example.com',
            password: 'secret',
          ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tapVisible(tester, find.text('OK'));
    expect(container.read(provider).requireValue.date, initialDate);
    expect(tester.takeException(), isNull);
  });
}
