import 'dart:async';
import 'dart:typed_data';
import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/user_model.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/controller/admin_image_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_providers.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_models.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/service/admin_repository.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_shell.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/service/profile_service.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/model/update_profile_payload.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'support/admin_fakes.dart';
import 'support/session_fakes.dart';

Future<void> launch(
  WidgetTester tester,
  ProviderContainer container, {
  String? path,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await container.read(sessionProvider.future);
  if (path != null) container.read(routerProvider).go(path);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: const App(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'live profile adapter preserves backend role and current session generation',
    () async {
      final adapter = AdminAdapter();
      final container = adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      final previous =
          container.read(sessionProvider).requireValue as Authenticated;
      final user = await ProfileService(container.read(dioProvider), null)
          .update(
            adminUser.id,
            const UpdateProfilePayload(
              name: 'Updated administrator',
              email: 'updated@example.test',
            ),
          );
      container.read(sessionProvider.notifier).updateUser(user);
      final current =
          container.read(sessionProvider).requireValue as Authenticated;
      expect(current.user.isAdmin, isTrue);
      expect(current.user.name, 'Updated administrator');
      expect(current.generation, previous.generation);
      expect(adapter.requests.last.data, {
        'name': 'Updated administrator',
        'email': 'updated@example.test',
      });
    },
  );
  test('only exact backend ADMIN grants admin; profile copies retain role', () {
    expect(adminUser.role, UserRole.admin);
    expect(adminUser.copyWith(name: 'Changed').role, UserRole.admin);
    for (final role in ['CUSTOMER', 'admin', '', 'SUPERADMIN', null, 1, true]) {
      expect(UserModel.fromJson({...adminJson, 'role': role}).isAdmin, isFalse);
    }
  });
  test('form validation follows backend ranges and package serialization', () {
    expect(AdminValidation.name(' '), isNotNull);
    expect(AdminValidation.name('x' * 201), isNotNull);
    expect(AdminValidation.slug('bad slug'), isNotNull);
    expect(AdminValidation.slug('wash-care-1'), isNull);
    for (final value in ['-1', '1.001', 'NaN', '1e2', '10000000000']) {
      expect(AdminValidation.money(value), isNotNull);
    }
    expect(AdminValidation.money('0.00'), isNull);
    expect(AdminValidation.integer('1441', min: 1, max: 1440), isNotNull);
    expect(AdminValidation.integer('1.5'), isNotNull);
    final items = [const PackageItem(serviceId: serviceId, quantity: 2)];
    expect(items.single.toJson(), {'serviceId': serviceId, 'quantity': 2});
    expect(AdminValidation.packageItems(items, {serviceId}), isNull);
    expect(
      AdminValidation.packageItems([...items, ...items], {serviceId}),
      isNotNull,
    );
    expect(AdminValidation.packageItems(items, {packageId}), isNotNull);
    expect(
      AdminValidation.packageItems(
        [const PackageItem(serviceId: serviceId, quantity: 0)],
        {serviceId},
      ),
      isNotNull,
    );
  });
  test(
    'offers validate discounts and Dhaka timestamps across date boundaries',
    () {
      final start = WorkshopTime.parse('2026-11-17 00:30')!;
      final end = WorkshopTime.parse('2026-11-17 01:30')!;
      expect(start.toIso8601String(), '2026-11-16T18:30:00.000Z');
      expect(WorkshopTime.input(start), '2026-11-17 00:30');
      expect(WorkshopTime.parse('2026-02-30 09:00'), isNull);
      expect(AdminValidation.offer('PERCENTAGE', '100', start, end), isNull);
      expect(
        AdminValidation.offer('PERCENTAGE', '100.01', start, end),
        isNotNull,
      );
      expect(AdminValidation.offer('FIXED_AMOUNT', '0', start, end), isNotNull);
      expect(
        AdminValidation.offer('FIXED_AMOUNT', '10', end, start),
        isNotNull,
      );
      final offer = AdminOffer.fromJson(offerJson);
      expect(offer.stateAt(offer.startsAt), 'Active');
      expect(
        offer.stateAt(offer.startsAt.subtract(const Duration(seconds: 1))),
        'Scheduled',
      );
      expect(offer.stateAt(offer.endsAt), 'Expired');
      expect(
        AdminOffer.fromJson({...offerJson, 'isActive': false}).stateAt(start),
        'Disabled',
      );
    },
  );
  test(
    'appointments only complete after end time and terminal states are read only',
    () {
      final pending = AdminAppointment.fromJson(appointmentJson());
      expect(pending.actionsAt(DateTime.now()), [
        BookingStatus.confirmed,
        BookingStatus.cancelled,
      ]);
      final confirmed = AdminAppointment.fromJson(
        appointmentJson(status: 'confirmed'),
      );
      expect(
        confirmed.actionsAt(
          confirmed.endsAt.subtract(const Duration(seconds: 1)),
        ),
        [BookingStatus.cancelled],
      );
      expect(confirmed.actionsAt(confirmed.endsAt), [
        BookingStatus.completed,
        BookingStatus.cancelled,
      ]);
      for (final status in ['completed', 'cancelled']) {
        expect(
          AdminAppointment.fromJson(
            appointmentJson(status: status),
          ).actionsAt(DateTime.now()),
          isEmpty,
        );
      }
    },
  );
  test(
    'multipart upload uses file, bytes and MIME without base64 JSON',
    () async {
      final adapter = AdminAdapter();
      final container = adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      final url = await container
          .read(adminRepositoryProvider)
          .upload(bytes, 'wash.jpg');
      expect(url, startsWith('https://'));
      final request = adapter.requests.last;
      expect(request.path, ApiEndpoints.adminImages);
      expect(request.headers['Authorization'], 'Bearer admin-token');
      final body = String.fromCharCodes(adapter.uploads.single);
      expect(body, contains('name="file"'));
      expect(body, contains('filename="wash.jpg"'));
      expect(body, contains('image/jpeg'));
      expect(
        () => AdminRepository.imageRequest(
          Uint8List(2 * 1024 * 1024 + 1),
          'huge.png',
        ),
        throwsFormatException,
      );
      expect(
        () => AdminRepository.imageRequest(bytes, 'file.svg'),
        throwsFormatException,
      );
    },
  );
  test(
    'mutation invalidates dashboard and catalog and suppresses duplicate submissions',
    () async {
      final adapter = AdminAdapter();
      final container = adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      final dashboard = container.listen(
        adminDashboardProvider(container.read(adminOwnerProvider)),
        (_, _) {},
      );
      final categories = container.listen(
        adminCategoriesProvider(container.read(adminOwnerProvider)),
        (_, _) {},
      );
      final catalog = container.listen(catalogControllerProvider, (_, _) {});
      final mutation = container.listen(adminMutationProvider, (_, _) {});
      addTearDown(() {
        dashboard.close();
        categories.close();
        catalog.close();
        mutation.close();
      });
      await container.read(
        adminDashboardProvider(container.read(adminOwnerProvider)).future,
      );
      await container.read(
        adminCategoriesProvider(container.read(adminOwnerProvider)).future,
      );
      await container.read(catalogControllerProvider.future);
      final oldCatalog = container.read(catalogControllerProvider.future);
      adapter.mutationGate = Completer<void>();
      final controller = container.read(adminMutationProvider.notifier);
      final first = controller.save(ApiEndpoints.adminCategories, {
        'name': 'New',
      });
      await adapter.mutationStarted.future;
      final second = await controller.save(ApiEndpoints.adminCategories, {
        'name': 'Duplicate',
      });
      expect(second.success, isFalse);
      adapter.mutationGate!.complete();
      expect((await first).success, isTrue);
      await container.read(
        adminCategoriesProvider(container.read(adminOwnerProvider)).future,
      );
      await container.read(
        adminDashboardProvider(container.read(adminOwnerProvider)).future,
      );
      expect(
        container.read(catalogControllerProvider.future),
        isNot(same(oldCatalog)),
      );
      expect(
        adapter.requests
            .where(
              (r) =>
                  r.path == ApiEndpoints.adminCategories && r.method == 'POST',
            )
            .length,
        1,
      );
      expect(
        adapter.requests
            .where(
              (r) =>
                  r.path == ApiEndpoints.adminCategories && r.method == 'GET',
            )
            .length,
        2,
      );
    },
  );
  test('409 refreshes details and exposes current appointment state', () async {
    final adapter = AdminAdapter();
    final container = adminContainer(adapter: adapter);
    await container.read(sessionProvider.future);
    container.listen(
      adminAppointmentProvider((
        owner: container.read(adminOwnerProvider),
        id: appointmentId,
      )),
      (_, _) {},
    );
    container.listen(adminMutationProvider, (_, _) {});
    await container.read(
      adminAppointmentProvider((
        owner: container.read(adminOwnerProvider),
        id: appointmentId,
      )).future,
    );
    adapter.mutationStatus = 409;
    final result = await container
        .read(adminMutationProvider.notifier)
        .transition(appointmentId, 'confirmed');
    expect(result.errorCode, 'CONFLICT');
    expect(
      (await container.read(
        adminAppointmentProvider((
          owner: container.read(adminOwnerProvider),
          id: appointmentId,
        )).future,
      )).status,
      BookingStatus.cancelled,
    );
  });
  test(
    'admin data clears on logout and reloads for a new admin session',
    () async {
      final adapter = AdminAdapter();
      final container = adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      container.listen(
        adminDashboardProvider(container.read(adminOwnerProvider)),
        (_, _) {},
      );
      await container.read(
        adminDashboardProvider(container.read(adminOwnerProvider)).future,
      );
      await container
          .read(sessionProvider.notifier)
          .login(email: 'admin@example.test', password: 'password');
      await container.read(
        adminDashboardProvider(container.read(adminOwnerProvider)).future,
      );
      expect(
        adapter.requests
            .where((r) => r.path == ApiEndpoints.adminDashboard)
            .length,
        2,
      );
      await container.read(sessionProvider.notifier).logout();
      await expectLater(
        container.read(
          adminDashboardProvider(container.read(adminOwnerProvider)).future,
        ),
        throwsA(isA<AdminFailure>()),
      );
      expect(
        container
            .read(adminDashboardProvider(container.read(adminOwnerProvider)))
            .hasValue,
        isFalse,
      );
    },
  );
  testWidgets(
    'restored admin routes to dashboard; role demotion revokes access',
    (tester) async {
      final container = adminContainer(adapter: AdminAdapter());
      await launch(tester, container);
      expect(
        container.read(routerProvider).routerDelegate.state.uri.path,
        '/admin',
      );
      expect(find.byType(AdminShell), findsOneWidget);
      final auth =
          container.read(sessionProvider).requireValue as Authenticated;
      expect(auth.user.isAdmin, isTrue);
      container
          .read(sessionProvider.notifier)
          .updateUser(
            UserEntity(
              id: adminUser.id,
              name: adminUser.name,
              email: adminUser.email,
            ),
          );
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routerDelegate.state.uri.path,
        '/home',
      );
      expect(find.byType(AdminShell), findsNothing);
    },
  );
  testWidgets('customer cannot use direct admin URL or admin login redirect', (
    tester,
  ) async {
    final adapter = AdminAdapter();
    final container = adminContainer(
      adapter: adapter,
      authenticated: false,
      user: testUser,
    );
    await launch(tester, container, path: '/admin/services/new');
    expect(
      container.read(routerProvider).routerDelegate.state.uri.path,
      '/login',
    );
    await container
        .read(sessionProvider.notifier)
        .login(email: testUser.email, password: 'password');
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routerDelegate.state.uri.path,
      '/home',
    );
    container.read(routerProvider).go('/admin/appointments/$appointmentId');
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routerDelegate.state.uri.path,
      '/home',
    );
    expect(adapter.requests.where((r) => r.path.startsWith('/admin')), isEmpty);
  });
  testWidgets(
    'admin login returns to admin deep link and logout clears private UI',
    (tester) async {
      final container = adminContainer(
        adapter: AdminAdapter(),
        authenticated: false,
      );
      await launch(tester, container, path: '/admin/categories');
      await container
          .read(sessionProvider.notifier)
          .login(email: adminUser.email, password: 'password');
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routerDelegate.state.uri.path,
        '/admin/categories',
      );
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routerDelegate.state.uri.path,
        '/login',
      );
      expect(find.byType(AdminShell), findsNothing);
    },
  );
  testWidgets(
    '403 remains a safe authorization error without repeated refresh',
    (tester) async {
      final adapter = AdminAdapter()..failStatus = 403;
      final container = adminContainer(adapter: adapter);
      await launch(tester, container);
      expect(
        find.text('You do not have permission to perform this action.'),
        findsOneWidget,
      );
      expect(
        adapter.requests
            .where((r) => r.path == ApiEndpoints.adminDashboard)
            .length,
        1,
      );
      expect(
        adapter.requests.where((r) => r.path.contains('/auth/refresh')),
        isEmpty,
      );
    },
  );
  testWidgets(
    'category and service forms show validation and send documented payloads',
    (tester) async {
      final adapter = AdminAdapter();
      final container = adminContainer(adapter: adapter);
      await launch(
        tester,
        container,
        path: '/admin/categories/new',
        width: 1280,
      );
      await tester.ensureVisible(find.text('Save category'));
      await tester.tap(find.text('Save category'));
      await tester.pumpAndSettle();
      expect(find.text('Enter 1–200 characters.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'New category');
      await tester.ensureVisible(find.text('Save category'));
      await tester.tap(find.text('Save category'));
      await tester.pumpAndSettle();
      expect(
        adapter.requests.lastWhere((r) => r.method == 'POST').data,
        containsPair('name', 'New category'),
      );
      container.read(routerProvider).go('/admin/services/new');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save service'));
      await tester.tap(find.text('Save service'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a nonnegative BDT amount with at most 2 decimals.'),
        findsOneWidget,
      );
    },
  );
  test(
    'failed upload retains old image and explicit retry constructs a new upload',
    () async {
      final adapter = AdminAdapter()..mutationStatus = 500;
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      final container = adminContainer(
        adapter: adapter,
        imagePicker: () async =>
            XFile.fromData(bytes, name: 'photo.jpg', path: 'photo.jpg'),
      );
      await container.read(sessionProvider.future);
      final provider = adminImageProvider((
        owner: Object(),
        initialUrl: 'https://example.test/old.jpg',
      ));
      container.listen(provider, (_, _) {});
      await container.read(provider.notifier).select();
      expect(container.read(provider).url, 'https://example.test/old.jpg');
      expect(container.read(provider).bytes, bytes);
      expect(container.read(provider).errorCode, 'SERVER_ERROR');
      expect(adapter.uploads.length, 1);
      adapter.mutationStatus = null;
      await container.read(provider.notifier).upload();
      expect(adapter.uploads.length, 2);
      expect(container.read(provider).url, contains('/media/images/'));
      expect(container.read(provider).bytes, isNull);
      expect(container.read(provider).errorCode, isNull);
      await container.read(sessionProvider.notifier).logout();
      expect(container.read(provider).url, 'https://example.test/old.jpg');
      expect(container.read(provider).bytes, isNull);
    },
  );
  test(
    'oversized selection is rejected before transport and server 413 is safe',
    () async {
      final adapter = AdminAdapter();
      final container = adminContainer(
        adapter: adapter,
        imagePicker: () async =>
            XFile.fromData(Uint8List(2 * 1024 * 1024 + 1), name: 'large.png'),
      );
      await container.read(sessionProvider.future);
      final provider = adminImageProvider((owner: Object(), initialUrl: null));
      container.listen(provider, (_, _) {});
      await container.read(provider.notifier).select();
      expect(container.read(provider).errorCode, 'IMAGE_TOO_LARGE');
      expect(adapter.uploads, isEmpty);
      adapter.mutationStatus = 413;
      final result = await ApiErrorHandler.run(
        () => container
            .read(adminRepositoryProvider)
            .upload(Uint8List.fromList([1, 2, 3]), 'small.png'),
      );
      expect(result.errorCode, 'IMAGE_TOO_LARGE');
    },
  );
  testWidgets(
    'package editor sends component UUID quantities and explicit price',
    (tester) async {
      final adapter = AdminAdapter();
      final container = adminContainer(adapter: adapter);
      await launch(tester, container, path: '/admin/packages/$packageId/edit');
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Quantity'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '3',
      );
      await tester.ensureVisible(find.text('Save package'));
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      final request = adapter.requests.lastWhere((r) => r.method == 'PATCH');
      expect(request.path, '${ApiEndpoints.adminServices}/$packageId');
      expect(request.data, containsPair('type', 'PACKAGE'));
      expect(request.data, containsPair('price', '500'));
      expect(request.data['packageItems'], [
        {'serviceId': serviceId, 'quantity': 3},
      ]);
      expect(
        container.read(routerProvider).routerDelegate.state.uri.path,
        '/admin/packages',
      );
    },
  );
  testWidgets(
    'offer editor serializes workshop dates as UTC and preserves discount type',
    (tester) async {
      final adapter = AdminAdapter();
      final container = adminContainer(adapter: adapter);
      await launch(
        tester,
        container,
        path: '/admin/offers/${offerJson['id']}/edit',
      );
      await tester.ensureVisible(find.text('Save offer'));
      await tester.tap(find.text('Save offer'));
      await tester.pumpAndSettle();
      final request = adapter.requests.lastWhere((r) => r.method == 'PATCH');
      expect(request.data['startsAt'], '2026-11-17T00:00:00.000Z');
      expect(request.data['endsAt'], '2026-11-18T00:00:00.000Z');
      expect(request.data['discountType'], 'PERCENTAGE');
    },
  );
  for (final (width, scale) in [
    (320.0, 1.0),
    (320.0, 2.0),
    (768.0, 1.0),
    (1280.0, 1.0),
    (1280.0, 2.0),
  ]) {
    testWidgets(
      'all admin screens fit width $width scale $scale and forms survive resize',
      (tester) async {
        final container = adminContainer(adapter: AdminAdapter());
        await launch(tester, container, width: width, scale: scale);
        final router = container.read(routerProvider);
        for (final path in [
          '/admin',
          '/admin/categories',
          '/admin/categories/new',
          '/admin/categories/$categoryId/edit',
          '/admin/services',
          '/admin/services/new',
          '/admin/services/$serviceId/edit',
          '/admin/packages',
          '/admin/packages/new',
          '/admin/packages/$packageId/edit',
          '/admin/offers',
          '/admin/offers/new',
          '/admin/offers/${offerJson['id']}/edit',
          '/admin/appointments',
          '/admin/appointments/$appointmentId',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
        router.go('/admin/services/new');
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'Draft wash');
        tester.view.physicalSize = Size(width == 1280 ? 390 : 1280, 900);
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(TextFormField, 'Draft wash'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test(
    'image fields are isolated per form and reset on session changes',
    () async {
      final container = adminContainer(adapter: AdminAdapter());
      await container.read(sessionProvider.future);
      final first = adminImageProvider((
        owner: Object(),
        initialUrl: 'https://example.test/first.png',
      ));
      final second = adminImageProvider((owner: Object(), initialUrl: null));
      container.listen(first, (_, _) {});
      container.listen(second, (_, _) {});
      expect(container.read(first).url, endsWith('first.png'));
      expect(container.read(second).url, isNull);
    },
  );
}
