import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/app/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/model/selected_image.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/service/admin_image_service.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/controller/appointments_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/create_booking_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/service/appointment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/service/booking_service.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_calendar.dart';

import 'support/demo_container.dart';

const serviceId = '11111111-1111-4111-8111-111111111111';
const slotId = '22222222-2222-4222-8222-222222222222';
const appointmentId = '33333333-3333-4333-8333-333333333333';

Map<String, dynamic> slotJson({bool available = true}) => {
  'id': slotId,
  'startsAt': '2026-11-20T04:00:00Z',
  'endsAt': '2026-11-20T04:30:00Z',
  'workshopTime': '2026-11-20T10:00:00',
  'timeZone': 'Asia/Dhaka',
  'available': available,
};

Map<String, dynamic> appointmentJson({bool canCancel = true}) => {
  'id': appointmentId,
  'serviceId': serviceId,
  'serviceName': 'Stored service name',
  'slot': slotJson(available: false),
  'status': 'pending',
  'price': 450.25,
  'originalPrice': 500,
  'currency': 'BDT',
  'durationMinutes': 30,
  'canCancel': canCancel,
  'paymentStatus': 'unpaid',
  'paymentMethod': null,
  'canPayOnline': true,
};

/// Mocked transport, including JSON decoding; no live requests or gateway calls.
class BookingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object? Function(RequestOptions)? respond;
  int status = 200;
  DioExceptionType? failure;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (failure != null && options.method == 'POST') {
      throw DioException(requestOptions: options, type: failure!);
    }
    final Object? body;
    if (respond != null) {
      body = respond!(options);
    } else if (options.path.endsWith('/availability')) {
      body = {
        'date': options.queryParameters['date'],
        'timeZone': 'Asia/Dhaka',
        'slots': [slotJson(available: status != 409)],
      };
    } else if (options.method == 'GET' && options.path == '/appointments') {
      body = [appointmentJson()];
    } else {
      body = appointmentJson();
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      options.method == 'POST' ? status : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('Dhaka today crosses UTC midnight at 18:00 UTC', () {
    expect(
      WorkshopCalendar.today(DateTime.parse('2026-11-16T17:59:59Z')),
      DateTime(2026, 11, 16),
    );
    expect(
      WorkshopCalendar.today(DateTime.parse('2026-11-16T18:00:00Z')),
      DateTime(2026, 11, 17),
    );
    expect(WorkshopCalendar.dateText(DateTime(2026, 1, 2)), '2026-01-02');
  });

  test('booking horizon includes today and ends after 29 calendar days', () {
    expect(
      WorkshopCalendar.lastDate(DateTime(2026, 12, 20), horizonDays: 30),
      DateTime(2027, 1, 18),
    );
  });

  test(
    'availability preserves UUID, UTC instant and workshop wall-clock fields',
    () async {
      final adapter = BookingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
        ..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final result = await BookingService(
        dio,
      ).getAvailability(serviceId, DateTime(2026, 11, 20));
      final request = adapter.requests.single;
      expect(request.uri.path, '/api/v1/services/$serviceId/availability');
      expect(request.queryParameters, {'date': '2026-11-20'});
      expect(request.extra[requestAccessKey], RequestAccess.public);
      expect(result.slots.single.id, slotId);
      expect(result.slots.single.startsAt, DateTime.utc(2026, 11, 20, 4));
      expect(Formatters.time(result.slots.single.workshopTime), '10:00 AM');
      expect(result.slots.single.workshopTime.isUtc, isTrue);
      expect(result.slots.single.endsAt, DateTime.utc(2026, 11, 20, 4, 30));
      expect(result.slots.single.available, isTrue);
    },
  );

  test(
    'missing, null and invalid availability never produce a bookable slot',
    () {
      for (final flag in [null, 'true', 1, {}, []]) {
        expect(
          () => TimeSlotModel.fromJson({...slotJson(), 'available': flag}),
          throwsFormatException,
        );
      }
      final missing = slotJson()..remove('available');
      expect(() => TimeSlotModel.fromJson(missing), throwsFormatException);
      expect(
        TimeSlotModel.fromJson(slotJson(available: false)).available,
        isFalse,
      );
    },
  );

  test(
    'invalid dates, timezones and mismatched wall-clock times are rejected',
    () {
      for (final changes in [
        {'workshopTime': '2026-11-20T11:00:00'},
        {'workshopTime': '2026-11-20T10:00:00Z'},
        {'workshopTime': '2026-02-30T10:00:00'},
        {'timeZone': 'UTC'},
        {'startsAt': '2026-11-20T04:00:00'},
        {'endsAt': '2026-11-20T04:30:00'},
        {'endsAt': '2026-11-20T03:30:00Z'},
      ]) {
        expect(
          () => TimeSlotModel.fromJson({...slotJson(), ...changes}),
          throwsFormatException,
        );
      }
      expect(
        () => AvailabilityModel.fromJson({
          'date': '2026-02-30',
          'timeZone': 'Asia/Dhaka',
          'slots': [],
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'all appointment adapters use authenticated paths and exact booking payload',
    () async {
      final container = demoContainer(demoData: false);
      await container.read(sessionProvider.future);
      final adapter = BookingAdapter();
      container.read(dioProvider).httpClientAdapter = adapter;
      final service = container.read(appointmentServiceProvider);
      expect(
        (await service.getBookings('ignored-local-user')).single.id,
        appointmentId,
      );
      expect(
        (await service.getBooking(
          'ignored-local-user',
          appointmentId,
        )).serviceName,
        'Stored service name',
      );
      final created = await service.create(
        'ignored-local-user',
        const CreateBookingPayload(serviceId: serviceId, slotId: slotId),
      );
      expect(created.price, 450.25);
      expect(created.originalPrice, 500);
      await service.cancel('ignored-local-user', appointmentId);
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'GET /appointments',
        'GET /appointments/$appointmentId',
        'POST /appointments',
        'PATCH /appointments/$appointmentId/cancel',
      ]);
      expect(adapter.requests[2].data, {
        'serviceId': serviceId,
        'slotId': slotId,
      });
      expect(adapter.requests[3].data, isNull);
      for (final request in adapter.requests) {
        expect(request.headers['Authorization'], 'Bearer demo-token');
        expect(request.extra[requestAccessKey], isNot(RequestAccess.public));
      }
    },
  );

  test(
    'server cancellation decision overrides pending status and survives copies',
    () {
      final appointment = AppointmentModel.fromJson(
        appointmentJson(canCancel: false),
      );
      expect(appointment.status, BookingStatus.pending);
      expect(appointment.canCancel, isFalse);
      expect(appointment.copyWith().canCancel, isFalse);
      final missing = appointmentJson()..remove('canCancel');
      expect(() => AppointmentModel.fromJson(missing), throwsFormatException);
    },
  );

  test('controller does not send cancel when server disallows it', () async {
    final container = demoContainer(demoData: false);
    await container.read(sessionProvider.future);
    final adapter = BookingAdapter()
      ..respond = (_) => appointmentJson(canCancel: false);
    container.read(dioProvider).httpClientAdapter = adapter;
    final provider = appointmentDetailsProvider(appointmentId);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    expect(await container.read(provider.notifier).cancel(), isFalse);
    expect(adapter.requests, hasLength(1));
  });

  for (final failure in [
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ]) {
    test(
      'live $failure creation refreshes bookings and never resubmits',
      () async {
        final container = demoContainer(demoData: false);
        await container.read(sessionProvider.future);
        final adapter = BookingAdapter()..failure = failure;
        container.read(dioProvider).httpClientAdapter = adapter;
        container.listen(appointmentsControllerProvider, (_, _) {});
        await container.read(appointmentsControllerProvider.future);
        final provider = bookingControllerProvider(serviceId);
        container.listen(provider, (_, _) {});
        await container.read(provider.future);
        final controller = container.read(provider.notifier);
        controller.selectSlot(slotId);
        controller.review();
        await Future.wait([controller.submit(), controller.submit()]);
        await controller.submit();
        expect(container.read(provider).requireValue.uncertain, isTrue);
        await container.read(appointmentsControllerProvider.future);
        expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
        expect(
          adapter.requests.where(
            (r) => r.path == '/appointments' && r.method == 'GET',
          ),
          hasLength(2),
        );
      },
    );
  }

  test('409 live conflict refreshes slots and clears selection', () async {
    final container = demoContainer(demoData: false);
    await container.read(sessionProvider.future);
    final adapter = BookingAdapter();
    container.read(dioProvider).httpClientAdapter = adapter;
    final provider = bookingControllerProvider(serviceId);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final controller = container.read(provider.notifier);
    controller.selectSlot(slotId);
    controller.review();
    adapter.status = 409;
    await controller.submit();
    final state = container.read(provider).requireValue;
    expect(state.step, BookingStep.schedule);
    expect(state.slotId, isNull);
    expect(state.availability!.slots.single.available, isFalse);
    expect(state.uncertain, isFalse);
    expect(
      adapter.requests.where((r) => r.path.endsWith('/availability')),
      hasLength(2),
    );
  });

  test(
    'Cloudinary and legacy HTTPS upload URLs are preserved verbatim',
    () async {
      for (final url in [
        'https://res.cloudinary.com/workshop/image/upload/v1/wash.webp',
        'https://api.example.test/api/v1/media/images/$slotId',
      ]) {
        final adapter = BookingAdapter()
          ..respond = (_) => {'id': slotId, 'imageUrl': url};
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
          ..httpClientAdapter = adapter;
        addTearDown(() => dio.close(force: true));
        expect(
          await AdminImageService(dio).upload(
            SelectedImage(Uint8List.fromList([0xff, 0xd8, 0xff]), 'wash.jpg'),
          ),
          url,
        );
      }
    },
  );

  test(
    'unconfigured image storage maps to a safe upload-specific message',
    () async {
      final adapter = BookingAdapter()..status = 503;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
        ..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final result = await ApiErrorHandler.run(
        () => AdminImageService(dio).upload(
          SelectedImage(Uint8List.fromList([0xff, 0xd8, 0xff]), 'wash.jpg'),
        ),
      );
      expect(result.errorCode, 'IMAGE_UPLOAD_UNAVAILABLE');
      expect(
        AppErrorMessages.messageFor(result.errorCode),
        contains('previous image is preserved'),
      );
    },
  );
}
