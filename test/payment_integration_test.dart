import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/app/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/payments/controller/admin_payment_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/controller/appointments_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/controller/payment_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/controller/reconciliation_gate.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_summary.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/service/payment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/platform_config.dart';
import 'package:assessment_project_fb_international_frontend/routes/router_provider.dart';

import 'live_booking_integration_test.dart' show appointmentJson, appointmentId;
import 'support/admin_fakes.dart' as admin;
import 'support/demo_container.dart';

Map<String, dynamic> attemptJson({
  String status = 'pending',
  bool applied = false,
}) => {
  'paymentId': 'payment-1',
  'appointmentId': appointmentId,
  'provider': 'sslcommerz',
  'status': status,
  'amount': 450.25,
  'currency': 'BDT',
  'checkoutUrl': status == 'pending'
      ? 'https://sandbox.sslcommerz.com/checkout'
      : null,
  'paidAt': applied ? '2026-11-17T12:01:00Z' : null,
  'applied': applied,
  'reasonCode': null,
  'createdAt': '2026-11-17T12:00:00Z',
  'updatedAt': '2026-11-17T12:01:00Z',
};

class PaymentAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  List<Map<String, dynamic>> attempts = [];
  bool uncertain = false, applied = false, enabled = true;
  Completer<void>? gate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    Object? body;
    if (options.path.endsWith('/pay')) {
      await gate?.future;
      attempts = [attemptJson()];
      if (uncertain) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      }
      body = attempts.single;
    } else if (options.path.endsWith('/reconcile')) {
      applied = true;
      attempts = [attemptJson(status: 'paid', applied: true)];
      body = attempts.single;
    } else if (options.path.endsWith('/payments')) {
      body = attempts;
    } else if (options.path == '/payments/config') {
      body = {
        'onlinePaymentEnabled': enabled,
        'provider': 'sslcommerz',
        'sandbox': true,
        'payAtWorkshopEnabled': true,
      };
    } else if (options.path.startsWith('/payments/')) {
      body = attempts.single;
    } else {
      body = {
        ...appointmentJson(),
        'paymentStatus': applied ? 'paid' : 'unpaid',
        'canPayOnline': !applied && attempts.isEmpty,
        'canCancel': !applied && attempts.isEmpty,
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const enabled = PaymentConfig(
    onlinePaymentEnabled: true,
    sandbox: true,
    payAtWorkshopEnabled: true,
  );
  final contact = CheckoutContact(
    phone: '+8801700000000',
    address: ' Dhaka ',
    city: ' Dhaka ',
    postcode: '1200',
  );
  test(
    'platform rejects missing, invalid or unsupported configuration and uses inclusive horizon',
    () {
      final json = {
        'booking': {
          'horizonDays': 7,
          'slotStepMinutes': 15,
          'timeZone': 'Asia/Dhaka',
        },
        'settings': {'faqs': []},
        'businessHours': [
          {
            'dayOfWeek': 1,
            'opensAt': '09:00',
            'closesAt': '18:00',
            'isClosed': false,
          },
        ],
      };
      final config = PlatformConfig.fromJson(json);
      expect(config.lastDate(DateTime(2026, 12, 29)), DateTime(2027, 1, 4));
      expect(config.businessHours.single.opensAt, '09:00');
      for (final booking in [
        {'horizonDays': 0, 'slotStepMinutes': 15, 'timeZone': 'Asia/Dhaka'},
        {'horizonDays': 30, 'slotStepMinutes': 15, 'timeZone': 'UTC'},
      ]) {
        expect(
          () => PlatformConfig.fromJson({...json, 'booking': booking}),
          throwsFormatException,
        );
      }
    },
  );
  test('direct requests reach transport without a health preflight', () async {
    final container = demoContainer(demoData: false);
    await container.read(sessionProvider.future);
    final adapter = PaymentAdapter();
    container.read(dioProvider).httpClientAdapter = adapter;
    await container.read(paymentServiceProvider).config();
    expect(adapter.requests.map((request) => request.path), [
      '/payments/config',
    ]);
  });
  test('payment config keeps workshop enabled when gateway disabled', () {
    final config = PaymentConfig.fromJson({
      'onlinePaymentEnabled': false,
      'provider': 'sslcommerz',
      'sandbox': true,
      'payAtWorkshopEnabled': true,
    });
    expect(config.onlinePaymentEnabled, false);
    expect(config.payAtWorkshopEnabled, true);
    expect(
      () => PaymentConfig.fromJson({'provider': 'other'}),
      throwsFormatException,
    );
  });
  test(
    'paid summary preserves pending appointment status and snapshot price',
    () {
      final appointment = AppointmentModel.fromJson({
        ...appointmentJson(),
        'paymentStatus': 'paid',
        'paymentMethod': 'sslcommerz',
        'canPayOnline': false,
        'canCancel': false,
      });
      expect(appointment.paymentStatus, PaymentSummary.paid);
      expect(appointment.status, BookingStatus.pending);
      expect(appointment.price, 450.25);
      expect(appointment.canCancel, false);
      expect(appointment.copyWith().paymentMethod, 'sslcommerz');
    },
  );
  test(
    'every attempt status parses independently from appointment summary',
    () {
      for (final status in PaymentStatus.values) {
        expect(
          PaymentAttempt.fromJson(attemptJson(status: status.apiValue)).status,
          status,
        );
      }
      expect(
        PaymentAttempt.fromJson(
          attemptJson(status: 'review_required', applied: true),
        ).applied,
        true,
      );
    },
  );
  test('contact validation trims input and serializes exactly four fields', () {
    expect(contact.toJson(), {
      'phone': '+8801700000000',
      'address': 'Dhaka',
      'city': 'Dhaka',
      'postcode': '1200',
    });
    for (final phone in ['', '123456', '+12345678901234567890', '123-45678']) {
      expect(CheckoutContact.validate('phone', phone), isNotNull);
    }
    expect(CheckoutContact.validate('phone', '+1234567890123456789'), isNull);
    expect(CheckoutContact.validate('city', ' '), isNotNull);
    expect(CheckoutContact.validate('address', 'a' * 51), isNotNull);
    expect(CheckoutContact.validate('postcode', 'a' * 31), isNotNull);
  });
  test(
    'a queued mutation is rejected after session ownership changes',
    () async {
      final gate = Completer<void>();
      final container = demoContainer(demoData: false);
      await container.read(sessionProvider.future);
      final adapter = PaymentAdapter();
      final started = Completer<void>();
      final dio = container.read(dioProvider);
      dio.httpClientAdapter = adapter;
      dio.interceptors.insert(
        1,
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            started.complete();
            await gate.future;
            handler.next(options);
          },
        ),
      );
      final result = ApiErrorHandler.run(
        () => container
            .read(dioProvider)
            .post(
              '/appointments',
              data: {'serviceId': 'service', 'slotId': 'slot'},
            ),
      );
      await started.future;
      await container.read(sessionProvider.notifier).logout();
      gate.complete();
      expect((await result).success, false);
      expect(adapter.requests, isEmpty);
    },
  );
  test(
    'disabled gateway prevents initiation even when a stale appointment permits it',
    () async {
      final container = demoContainer(demoData: false);
      await container.read(sessionProvider.future);
      final adapter = PaymentAdapter()..enabled = false;
      container.read(dioProvider).httpClientAdapter = adapter;
      final provider = paymentControllerProvider((
        identity: container.read(sessionIdentityProvider),
        appointmentId: appointmentId,
      ));
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      await container.read(provider.notifier).initiate(contact);
      expect(adapter.requests.where((r) => r.path.endsWith('/pay')), isEmpty);
      expect(container.read(provider).requireValue.busy, false);
    },
  );
  test(
    'checkout trusts exact environment hosts, https, no user info or unusual port',
    () {
      expect(
        trustedCheckoutUri(
          'https://sandbox-gw.sslcommerz.com/checkout',
          enabled,
        ).host,
        'sandbox-gw.sslcommerz.com',
      );
      for (final url in [
        'http://sandbox.sslcommerz.com/x',
        'https://sandbox.sslcommerz.com.attacker.test/x',
        'https://user:pass@sandbox.sslcommerz.com/x',
        'https://securepay.sslcommerz.com/x',
        'https://sandbox.sslcommerz.com:8443/x',
        'javascript:alert(1)',
      ]) {
        expect(() => trustedCheckoutUri(url, enabled), throwsFormatException);
      }
      expect(
        () => trustedCheckoutUri(
          'https://sandbox.sslcommerz.com/x',
          PaymentConfig.demo,
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'checkout policy and launch errors belong to the payment controller',
    () async {
      final container = demoContainer(demoData: false);
      await container.read(sessionProvider.future);
      final adapter = PaymentAdapter()..attempts = [attemptJson()];
      container.read(dioProvider).httpClientAdapter = adapter;
      final provider = paymentControllerProvider((
        identity: container.read(sessionIdentityProvider),
        appointmentId: appointmentId,
      ));
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final controller = container.read(provider.notifier);
      final unsafe = PaymentAttempt.fromJson({
        ...attemptJson(),
        'checkoutUrl': 'https://attacker.test/checkout',
      });
      expect(controller.prepareCheckout(unsafe, enabled), isNull);
      expect(container.read(provider).requireValue.checkoutError, isNotNull);
      final attempt = PaymentAttempt.fromJson(attemptJson());
      expect(controller.prepareCheckout(attempt, enabled)?.scheme, 'https');
      controller.checkoutLaunchCompleted(true);
      expect(container.read(provider).requireValue.checkoutError, isNull);
      await container.read(sessionProvider.notifier).logout();
      await container.pump();
      final afterLogout = container.read(provider);
      controller.checkoutLaunchCompleted(false);
      expect(container.read(provider), same(afterLogout));
    },
  );
  test(
    'reconciliation excludes simultaneous calls and enforces spacing after completion',
    () async {
      var now = DateTime.utc(2026);
      final throttle = ReconciliationGate(now: () => now);
      final gate = Completer<int>();
      final first = throttle.run('payment', () => gate.future);
      expect(await throttle.run('payment', () async => 2), isNull);
      gate.complete(1);
      expect(await first, 1);
      now = now.add(const Duration(seconds: 4));
      expect(await throttle.run('payment', () async => 2), isNull);
      now = now.add(const Duration(seconds: 1));
      expect(await throttle.run('payment', () async => 2), 2);
    },
  );
  for (final uncertain in [false, true]) {
    test(
      'initiation ${uncertain ? 'recovers ambiguous timeout without duplicate charge' : 'uses exact contact payload and syncs appointment state'}',
      () async {
        final container = demoContainer(demoData: false);
        await container.read(sessionProvider.future);
        final adapter = PaymentAdapter()..uncertain = uncertain;
        container.read(dioProvider).httpClientAdapter = adapter;
        final key = (
          identity: container.read(sessionIdentityProvider),
          appointmentId: appointmentId,
        );
        final provider = paymentControllerProvider(key);
        final sub = container.listen(provider, (_, _) {});
        addTearDown(sub.close);
        await container.read(provider.future);
        final controller = container.read(provider.notifier);
        final result = await controller.initiate(contact);
        expect(
          adapter.requests.where((r) => r.path.endsWith('/pay')).length,
          1,
        );
        expect(
          adapter.requests.firstWhere((r) => r.path.endsWith('/pay')).data,
          contact.toJson(),
        );
        if (uncertain) {
          expect(result, isNull);
        } else {
          expect(result!.status, PaymentStatus.pending);
          await controller.refresh();
        }
        expect(
          container.read(provider).requireValue.appointment.paymentStatus,
          PaymentSummary.paid,
        );
        expect(
          container.read(provider).requireValue.appointment.status,
          BookingStatus.pending,
        );
        await controller.initiate(contact);
        expect(
          adapter.requests.where((r) => r.path.endsWith('/pay')).length,
          1,
        );
        expect(
          adapter.requests.where((r) => r.path.endsWith('/reconcile')).length,
          1,
        );
        // A details fetch sees the same authoritative summary.
        expect(
          (await container.read(
            appointmentDetailsProvider(appointmentId).future,
          )).appointment!.paymentStatus,
          PaymentSummary.paid,
        );
      },
    );
  }
  test(
    'session changes prevent late payment results reaching another account',
    () async {
      final container = demoContainer(demoData: false);
      await container.read(sessionProvider.future);
      final adapter = PaymentAdapter()..gate = Completer<void>();
      container.read(dioProvider).httpClientAdapter = adapter;
      final provider = paymentControllerProvider((
        identity: container.read(sessionIdentityProvider),
        appointmentId: appointmentId,
      ));
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container.read(provider.future);
      final pending = container.read(provider.notifier).initiate(contact);
      while (!adapter.requests.any((r) => r.path.endsWith('/pay'))) {
        await Future<void>.delayed(Duration.zero);
      }
      await container.read(sessionProvider.notifier).logout();
      adapter.gate!.complete();
      expect(await pending, isNull);
    },
  );
  test(
    'admin list filters use exact status and customers cannot invoke admin payment providers',
    () async {
      final adapter = admin.AdminAdapter();
      final container = admin.adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      final owner = container.read(adminOwnerProvider);
      final provider = adminPaymentsProvider((
        owner: owner,
        status: 'review_required',
      ));
      expect(await container.read(provider.future), isEmpty);
      final request = adapter.requests.lastWhere(
        (r) => r.path == '/admin/payments',
      );
      expect(request.queryParameters, {'status': 'review_required'});
      final customer = demoContainer(demoData: false);
      await customer.read(sessionProvider.future);
      expect(customer.read(adminOwnerProvider).authorized, false);
      await expectLater(
        customer.read(
          adminPaymentsProvider((
            owner: customer.read(adminOwnerProvider),
            status: null,
          )).future,
        ),
        throwsA(isA<AdminFailure>()),
      );
    },
  );
  test(
    'admin payment DTO includes references/incidents without exposing checkout',
    () {
      final json = {...attemptJson(status: 'review_required', applied: true)}
        ..remove('checkoutUrl');
      final payment = AdminPayment.fromJson({
        ...json,
        'merchantTransactionId': 'AC123',
        'validationId': 'VAL123',
        'bankTransactionId': 'BANK123',
        'customer': {'name': 'Customer', 'email': 'customer@example.test'},
        'serviceName': 'Stored service',
        'lastReconciledAt': '2026-11-17T12:01:00Z',
        'gatewayIncidents': [
          {
            'validationId': 'VAL456',
            'bankTransactionId': 'BANK456',
            'reasonCode': 'ADDITIONAL_CHARGE',
          },
        ],
      });
      expect(payment.attempt.checkoutUrl, isNull);
      expect(payment.incidents.single.reasonCode, 'ADDITIONAL_CHARGE');
      expect(payment.customerName, 'Customer');
      expect(payment.attempt.applied, true);
    },
  );
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'payment screen and disabled gateway render without overflow at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = demoContainer(demoData: false);
        await container.read(sessionProvider.future);
        container.read(dioProvider).httpClientAdapter = PaymentAdapter()
          ..enabled = false;
        container.read(routerProvider).go('/bookings/$appointmentId/payment');
        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pay at Workshop'), findsOneWidget);
        expect(find.text('Pay Online'), findsNothing);
        expect(find.text('Refresh Payment Status'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test(
    'confirmed payment errors preserve safe domain-specific messages',
    () async {
      for (final code in [
        'PAYMENT_NOT_ELIGIBLE',
        'APPOINTMENT_ALREADY_PAID',
        'PAYMENT_UNRESOLVED',
        'PAYMENT_REVIEW_REQUIRED',
        'PAYMENT_CANCELLATION_BLOCKED',
        'PAYMENT_CONTACT_UNSUPPORTED',
        'PAYMENT_RATE_LIMITED',
        'PAYMENT_RECONCILE_THROTTLED',
        'PAYMENTS_DISABLED',
        'PAYMENT_INITIATION_UNCERTAIN',
        'PAYMENT_GATEWAY_UNAVAILABLE',
        'PAYMENT_VERIFICATION_UNAVAILABLE',
      ]) {
        final options = RequestOptions(path: '/payments');
        final result = await ApiErrorHandler.run(
          () async => throw DioException.badResponse(
            statusCode: 503,
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 503,
              data: {'code': code, 'message': 'secret provider exception'},
            ),
          ),
        );
        expect(result.errorCode, code);
        expect(AppErrorMessages.messageFor(code), isNot(contains('secret')));
      }
    },
  );
}
