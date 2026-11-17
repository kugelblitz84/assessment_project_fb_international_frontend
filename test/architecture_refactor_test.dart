import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/core/network/backend_policy.dart';
import 'package:assessment_project_fb_international_frontend/core/network/cookie_transport.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/interceptors/csrf_interceptor.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/input_validation_exception.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/category_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/model/selected_image.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/offer_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/service_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/service_details_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/controller/payment_config_provider.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/controller/payment_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/service/payment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/controller/platform_config_provider.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/service/platform_config_service.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

import 'support/admin_fakes.dart' as admin;
import 'support/demo_container.dart';
import 'support/session_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final FutureOr<(Object?, int)> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    final (body, status) = await respond(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _client(_Adapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;

class _IntentCookies extends CookieTransport {
  _IntentCookies() : super(Uri.parse('https://api.example.test'));
  bool blocked = false;
  @override
  Future<bool> canRestoreSession() async => true;
  @override
  Future<bool> restorationBlocked() async => blocked;
  @override
  Future<void> blockRestoration() async {
    blocked = true;
  }

  @override
  Future<void> allowRestoration() async {
    blocked = false;
  }

  @override
  Future<void> clear() async {
    blocked = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uncached direct links use the detail endpoint while catalog entries render immediately',
    () async {
      final container = demoContainer(demoData: false);
      final adapter = _Adapter(
        (request) => request.path == '/services'
            ? (<Object?>[], 200)
            : (admin.serviceJson(), 200),
      );
      container.read(dioProvider).httpClientAdapter = adapter;
      container.listen(catalogControllerProvider, (_, _) {});
      await container.read(catalogControllerProvider.future);
      final details = serviceDetailsProvider(admin.serviceId);
      container.listen(details, (_, _) {});
      await container.read(
        serviceDetailsRequestProvider(admin.serviceId).future,
      );
      await container.pump();
      expect(container.read(details).requireValue?.id, admin.serviceId);
      expect(adapter.requests.map((request) => request.path), [
        '/services',
        '/services/${admin.serviceId}',
      ]);
    },
  );

  test(
    'admin catalog mutations invalidate the direct-link cache as well as catalog state',
    () async {
      final adapter = admin.AdminAdapter();
      final container = admin.adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      final details = serviceDetailsRequestProvider(admin.serviceId);
      container.listen(details, (_, _) {});
      container.listen(adminServiceMutationProvider, (_, _) {});
      await container.read(details.future);
      expect(
        (await container
                .read(adminServiceMutationProvider.notifier)
                .setActive(admin.serviceId, false))
            .success,
        isTrue,
      );
      await container.read(details.future);
      expect(
        adapter.requests.where(
          (request) => request.path == '/services/${admin.serviceId}',
        ),
        hasLength(2),
      );
      expect(
        adapter.requests
            .singleWhere((request) => request.method == 'PATCH')
            .data,
        {'isActive': false},
      );
    },
  );

  for (final (body, status, code) in <(Object?, int, String)>[
    ({}, 503, 'BACKEND_UNAVAILABLE'),
    ({'booking': {}}, 200, 'INVALID_RESPONSE'),
  ]) {
    test(
      'platform failure $status is normalized without fallback or implicit retry',
      () async {
        final adapter = _Adapter((_) => (body, status));
        final dio = _client(adapter);
        addTearDown(dio.close);
        final container = ProviderContainer.test(
          overrides: [
            platformConfigServiceProvider.overrideWithValue(
              PlatformConfigService(dio),
            ),
          ],
        );
        container.listen(platformConfigProvider, (_, _) {});
        await expectLater(
          container.read(platformConfigProvider.future),
          throwsA(isA<ApiFailure>().having((e) => e.code, 'code', code)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 220));
        expect(adapter.requests, hasLength(1));
      },
    );
  }

  test(
    'payment configuration failures retain safe standardized codes',
    () async {
      final adapter = _Adapter((_) => ({}, 500));
      final dio = _client(adapter);
      addTearDown(dio.close);
      final container = ProviderContainer.test(
        overrides: [
          paymentServiceProvider.overrideWithValue(PaymentService(dio)),
        ],
      );
      container.listen(paymentConfigProvider, (_, _) {});
      await expectLater(
        container.read(paymentConfigProvider.future),
        throwsA(
          isA<ApiFailure>().having((e) => e.code, 'code', 'SERVER_ERROR'),
        ),
      );
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'initial payment history failure is normalized and never initiates a payment',
    () async {
      final container = demoContainer(demoData: false);
      await container.read(sessionProvider.future);
      final adapter = _Adapter((_) => ({}, 403));
      container.read(dioProvider).httpClientAdapter = adapter;
      final provider = paymentControllerProvider((
        identity: container.read(sessionIdentityProvider),
        appointmentId: 'booking',
      ));
      container.listen(provider, (_, _) {});
      await expectLater(
        container.read(provider.future),
        throwsA(isA<ApiFailure>().having((e) => e.code, 'code', 'FORBIDDEN')),
      );
      expect(adapter.requests.map((request) => request.path), [
        '/appointments/booking/payments',
      ]);
    },
  );

  test(
    'browser CSRF is acquired from the trusted API and attached only to logout/refresh',
    () async {
      final adapter = _Adapter(
        (request) => request.path == '/auth/csrf'
            ? ({'csrfToken': 'test-csrf'}, 200)
            : ({}, 200),
      );
      final dio = _client(adapter);
      addTearDown(dio.close);
      dio.interceptors.add(
        CsrfInterceptor(dio, BackendPolicy(Uri.parse(dio.options.baseUrl))),
      );
      await dio.post<Object?>('/auth/logout');
      expect(adapter.requests.map((request) => request.path), [
        '/auth/csrf',
        '/auth/logout',
      ]);
      expect(adapter.requests.last.headers['X-CSRF-Token'], 'test-csrf');
      await dio.get<Object?>('/services');
      expect(adapter.requests.last.headers['X-CSRF-Token'], isNull);
    },
  );

  test(
    'malformed CSRF retains its typed cause and never dispatches the mutation',
    () async {
      final adapter = _Adapter((_) => ({'csrfToken': 42}, 200));
      final dio = _client(adapter);
      addTearDown(dio.close);
      dio.interceptors.add(
        CsrfInterceptor(dio, BackendPolicy(Uri.parse(dio.options.baseUrl))),
      );
      final result = await ApiErrorHandler.run(
        () => dio.post<Object?>('/auth/refresh'),
      );
      expect(result.errorCode, 'INVALID_RESPONSE');
      expect(adapter.requests.map((request) => request.path), ['/auth/csrf']);
    },
  );

  test(
    'failed server logout cannot restore an HttpOnly cookie without an explicit login',
    () async {
      final cookies = _IntentCookies();
      final storage = MemoryTokenStorage('saved-token');
      final repository = StubAuthRepository()
        ..logoutError = const AuthRequestException('Unavailable');
      ProviderContainer create() => ProviderContainer.test(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repository),
          cookieTransportProvider.overrideWithValue(cookies),
        ],
      );
      final first = create();
      await first.read(sessionProvider.future);
      await first.read(sessionProvider.notifier).logout();
      expect(cookies.blocked, isTrue);
      expect(storage.token, isNull);
      final reloaded = create();
      expect(
        await reloaded.read(sessionProvider.future),
        isA<Unauthenticated>(),
      );
      expect(repository.refreshCalls, 0);
      await reloaded
          .read(sessionProvider.notifier)
          .login(email: testUser.email, password: 'password');
      expect(cookies.blocked, isFalse);
    },
  );

  test(
    'secure-storage and local-input failures are distinct from malformed responses',
    () async {
      expect(
        (await ApiErrorHandler.run<void>(
          () async => throw const SecureStorageException(),
        )).errorCode,
        'SECURE_STORAGE_ERROR',
      );
      expect(
        (await ApiErrorHandler.run<void>(
          () async => throw const InputValidationException(),
        )).errorCode,
        'VALIDATION_ERROR',
      );
      final request = RequestOptions(path: '/appointments');
      expect(
        (await ApiErrorHandler.run<void>(
          () async => throw DioException.badResponse(
            statusCode: 413,
            requestOptions: request,
            response: Response<Object?>(
              requestOptions: request,
              statusCode: 413,
            ),
          ),
        )).errorCode,
        'PAYLOAD_TOO_LARGE',
      );
      expect(ApiErrorMessages.messageFor('CANCELLED'), isEmpty);
    },
  );

  test(
    'typed admin inputs preserve money, null images, quantities and UTC timestamps',
    () {
      final category = const CategoryPayload(
        name: '  Wash  ',
        imageUrl: null,
      ).toJson();
      expect(category, {
        'name': 'Wash',
        'description': '',
        'sortOrder': 0,
        'isActive': true,
        'imageUrl': null,
      });
      final items = [const PackageItem(serviceId: 'individual', quantity: 2)];
      final payload = ServicePayload(
        name: 'Package',
        description: '',
        categoryId: 'category',
        type: 'PACKAGE',
        price: '1200.50',
        durationMinutes: 90,
        inclusions: ['Inspection'],
        packageItems: items,
      );
      items.clear();
      expect(payload.validate({'individual'}), isNull);
      expect(payload.toJson()['price'], '1200.50');
      expect(payload.toJson()['packageItems'], [
        {'serviceId': 'individual', 'quantity': 2},
      ]);
      final offer = OfferPayload(
        serviceId: 'service',
        title: 'Offer',
        description: '',
        discountType: 'FIXED_AMOUNT',
        discountValue: '50.25',
        startsAt: DateTime.parse('2026-11-20T10:00:00+06:00'),
        endsAt: DateTime.parse('2026-11-21T10:00:00+06:00'),
      );
      expect(offer.toJson()['discountValue'], '50.25');
      expect(offer.toJson()['startsAt'], '2026-11-20T04:00:00.000Z');
    },
  );

  test('selected images own immutable bytes and validate before transport', () {
    final source = Uint8List.fromList([1, 2, 3]);
    final selected = SelectedImage(source, 'wash.WEBP');
    source[0] = 9;
    expect(selected.bytes.first, 1);
    expect(selected.mimeSubtype, 'webp');
    expect(() => selected.bytes[0] = 2, throwsUnsupportedError);
    expect(
      () => SelectedImage(Uint8List(0), 'wash.png'),
      throwsA(isA<InputValidationException>()),
    );
  });

  test('required service fields are never replaced with bookable defaults', () {
    final json = admin.serviceJson();
    for (final field in ['available', 'type', 'inclusions']) {
      final missing = Map<String, dynamic>.from(json)..remove(field);
      expect(() => ServiceModel.fromJson(missing), throwsFormatException);
    }
  });

  test('expired selected slots cannot continue or submit', () {
    final past = DateTime.now().subtract(const Duration(minutes: 1));
    final state = BookingState(
      date: past,
      slotId: 'expired',
      availability: AvailabilityModel(
        date: past,
        timeZone: 'Asia/Dhaka',
        slots: [
          TimeSlotModel(
            id: 'expired',
            startsAt: past,
            workshopTime: past,
            timeZone: 'Asia/Dhaka',
          ),
        ],
      ),
    );
    expect(state.selectedSlot, isNull);
    expect(state.canContinue, isFalse);
  });

  test(
    'repeated browse actions produce a single route intent with a new request identity',
    () {
      final first = Uri.parse(AppRoutes.browseServicesLocation('category'));
      final second = Uri.parse(AppRoutes.browseServicesLocation('category'));
      expect(first.path, '/home');
      expect(first.queryParameters['category'], 'category');
      expect(first.queryParameters['browse'], 'all');
      expect(
        first.queryParameters['intent'],
        isNot(second.queryParameters['intent']),
      );
    },
  );
}
