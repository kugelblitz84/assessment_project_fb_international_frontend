import 'dart:async';
import 'package:assessment_project_fb_international_frontend/core/session/application/current_user_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/controller/assistant_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_message_model.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_request_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/service/assistant_service.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/service/booking_service.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/controller/profile_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/model/update_profile_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/controller/appointments_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/model/availability_model.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/model/create_booking_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/service/appointment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/service/demo_workshop.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/demo_container.dart';

void main() {
  test(
    'catalogue filtering and validated category deep links share one catalogue',
    () async {
      final container = demoContainer();
      final catalog = await container.read(catalogControllerProvider.future);
      expect(catalog.services, hasLength(6));
      container.read(homeControllerProvider.notifier).search('oil');
      expect(container.read(filteredServicesProvider).single.id, 'oil-change');
      await container
          .read(homeControllerProvider.notifier)
          .browse('inspection');
      expect(container.read(filteredServicesProvider), hasLength(3));
      await container
          .read(homeControllerProvider.notifier)
          .browse('invented-category');
      expect(container.read(filteredServicesProvider), hasLength(6));
    },
  );

  test(
    'booking submits once, loads by ID, cancels, and releases availability',
    () async {
      final container = demoContainer();
      await container.read(sessionProvider.future);
      final provider = bookingControllerProvider('exterior-wash');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final controller = container.read(provider.notifier);
      await controller.selectDate(
        DemoWorkshop.today.add(const Duration(days: 3)),
      );
      final slot = container
          .read(provider)
          .requireValue
          .availability!
          .slots
          .firstWhere((s) => s.available);
      controller.selectSlot(slot.id);
      controller.review();
      await Future.wait([controller.submit(), controller.submit()]);
      final booking = container.read(provider).requireValue.created!;
      expect(booking.status, BookingStatus.pending);
      final list = await container.read(appointmentsControllerProvider.future);
      expect(list.items.where((b) => b.id == booking.id), hasLength(1));
      final detailProvider = appointmentDetailsProvider(booking.id);
      container.listen(detailProvider, (_, _) {});
      expect(
        (await container.read(detailProvider.future)).appointment!.slot.id,
        slot.id,
      );
      expect(await container.read(detailProvider.notifier).cancel(), isTrue);
      expect(
        container.read(detailProvider).requireValue.appointment!.status,
        BookingStatus.cancelled,
      );
      expect(
        (await container.read(
          appointmentsControllerProvider.future,
        )).items.firstWhere((b) => b.id == booking.id).status,
        BookingStatus.cancelled,
      );
      final availability = await container
          .read(bookingServiceProvider)
          .getAvailability('exterior-wash', slot.workshopTime);
      expect(
        availability.slots.firstWhere((s) => s.id == slot.id).available,
        isTrue,
      );
    },
  );

  test(
    'a concurrent slot conflict returns to schedule without a second booking',
    () async {
      final container = demoContainer();
      await container.read(sessionProvider.future);
      final provider = bookingControllerProvider('exterior-wash');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final controller = container.read(provider.notifier);
      await controller.selectDate(
        DemoWorkshop.today.add(const Duration(days: 3)),
      );
      final slot = container
          .read(provider)
          .requireValue
          .availability!
          .slots
          .firstWhere((s) => s.available);
      controller.selectSlot(slot.id);
      controller.review();
      await container
          .read(appointmentServiceProvider)
          .create(
            'another-driver',
            CreateBookingPayload(serviceId: 'exterior-wash', slotId: slot.id),
          );
      await controller.submit();
      final state = container.read(provider).requireValue;
      expect(state.created, isNull);
      expect(state.step, 0);
      expect(state.slotId, isNull);
      expect(state.errorCode, 'CONFLICT');
      expect(
        state.availability!.slots.firstWhere((s) => s.id == slot.id).available,
        isFalse,
      );
    },
  );

  test(
    'a slow previous date cannot overwrite the latest selected date',
    () async {
      late RacingBookingService service;
      final container = demoContainer(
        bookingFactory: (dio, demo) =>
            service = RacingBookingService(dio, demo),
      );
      await container.read(sessionProvider.future);
      final provider = bookingControllerProvider('exterior-wash');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final controller = container.read(provider.notifier);
      final oldDay = DemoWorkshop.today.add(const Duration(days: 3));
      final latestDay = DemoWorkshop.today.add(const Duration(days: 4));
      service.gates[oldDay] = Completer<AvailabilityModel>();
      final oldRequest = controller.selectDate(oldDay);
      await controller.selectDate(latestDay);
      service.gates[oldDay]!.complete(
        service.demo!.availability('exterior-wash', oldDay),
      );
      await oldRequest;
      expect(container.read(provider).requireValue.date, latestDay);
      expect(
        container.read(provider).requireValue.availability!.date,
        latestDay,
      );
    },
  );

  test(
    'ambiguous creation failure blocks duplicate submissions and retains the draft',
    () async {
      late TimeoutAppointmentService service;
      final container = demoContainer(
        appointmentFactory: (dio, demo) =>
            service = TimeoutAppointmentService(dio, demo),
      );
      await container.read(sessionProvider.future);
      final provider = bookingControllerProvider('oil-change');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final controller = container.read(provider.notifier);
      await controller.selectDate(
        DemoWorkshop.today.add(const Duration(days: 4)),
      );
      final slot = container
          .read(provider)
          .requireValue
          .availability!
          .slots
          .firstWhere((s) => s.available);
      controller.selectSlot(slot.id);
      controller.review();
      await controller.submit();
      await controller.submit();
      expect(service.calls, 1);
      expect(container.read(provider).requireValue.uncertain, isTrue);
      expect(container.read(provider).requireValue.slotId, slot.id);
    },
  );

  test(
    'profile save updates the existing session user and private data clears on logout',
    () async {
      final container = demoContainer();
      await container.read(sessionProvider.future);
      container.listen(profileControllerProvider, (_, _) {});
      container.listen(assistantControllerProvider, (_, _) {});
      container.listen(appointmentsControllerProvider, (_, _) {});
      await container.read(appointmentsControllerProvider.future);
      expect(
        await container
            .read(profileControllerProvider.notifier)
            .save(
              const UpdateProfilePayload(
                name: 'Updated Driver',
                email: 'updated@example.com',
              ),
            ),
        isTrue,
      );
      expect(container.read(currentUserProvider)!.name, 'Updated Driver');
      await container
          .read(assistantControllerProvider.notifier)
          .send('battery check');
      expect(container.read(assistantControllerProvider).messages, isNotEmpty);
      await container.read(sessionProvider.notifier).logout();
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(assistantControllerProvider).messages, isEmpty);
      final bookings = await container.read(
        appointmentsControllerProvider.future,
      );
      expect(bookings.items, isEmpty);
      expect(bookings.ownerId, isNull);
    },
  );

  test(
    'assistant retry retains one user message and drops unknown service actions',
    () async {
      final container = demoContainer(
        authenticated: false,
        assistantFactory: RetryingAssistantService.new,
      );
      await container.read(sessionProvider.future);
      final controller = container.read(assistantControllerProvider.notifier);
      await controller.send('wash');
      expect(
        container.read(assistantControllerProvider).messages,
        hasLength(1),
      );
      expect(
        container.read(assistantControllerProvider).errorCode,
        'NETWORK_ERROR',
      );
      await controller.retry();
      final state = container.read(assistantControllerProvider);
      expect(state.messages, hasLength(2));
      expect(state.errorCode, isNull);
      expect(state.messages.last.actions.single.serviceId, 'exterior-wash');
    },
  );

  test(
    'disabling demo data fails explicitly instead of guessing HTTP endpoints',
    () async {
      final container = demoContainer(demoData: false);
      final state = await container.read(catalogControllerProvider.future);
      expect(state.services, isEmpty);
      expect(state.errorCode, 'NOT_CONFIGURED');
    },
  );

  test(
    'late private booking data cannot replace a new account’s results',
    () async {
      late GatedAppointmentService service;
      final container = demoContainer(
        appointmentFactory: (dio, demo) =>
            service = GatedAppointmentService(dio, demo),
      );
      await container.read(sessionProvider.future);
      container.listen(appointmentsControllerProvider, (_, _) {});
      await service.started.future;
      final oldItems = service.demo!.appointments('demo-driver');
      await container.read(sessionProvider.notifier).logout();
      await container
          .read(sessionProvider.notifier)
          .login(email: 'new-driver@example.com', password: 'demo');
      final latest = await container.read(
        appointmentsControllerProvider.future,
      );
      expect(latest.ownerId, 'new-driver@example.com');
      service.gate.complete(oldItems);
      await Future<void>.delayed(Duration.zero);
      final visible = container
          .read(appointmentsControllerProvider)
          .requireValue;
      expect(visible.ownerId, 'new-driver@example.com');
      expect(
        visible.items.any((a) => a.id.startsWith('demo-driver-')),
        isFalse,
      );
    },
  );

  test('an in-flight assistant response is discarded after logout', () async {
    late GatedAssistantService service;
    final container = demoContainer(
      assistantFactory: (dio, demo) =>
          service = GatedAssistantService(dio, demo),
    );
    await container.read(sessionProvider.future);
    container.listen(assistantControllerProvider, (_, _) {});
    final pending = container
        .read(assistantControllerProvider.notifier)
        .send('private question');
    // The request first waits for the shared catalogue.
    await container.read(catalogControllerProvider.future);
    await Future<void>.delayed(Duration.zero);
    await service.started.future;
    await container.read(sessionProvider.notifier).logout();
    service.gate.complete(
      const AssistantMessageModel(
        id: 'old-reply',
        role: AssistantRole.assistant,
        text: 'Old account reply',
      ),
    );
    await pending;
    expect(container.read(assistantControllerProvider).messages, isEmpty);
  });
}

class GatedAppointmentService extends AppointmentService {
  GatedAppointmentService(super.dio, super.demo);
  final started = Completer<void>();
  final gate = Completer<List<AppointmentModel>>();
  @override
  Future<List<AppointmentModel>> getBookings(String userId) {
    if (userId != 'demo-driver') return super.getBookings(userId);
    if (!started.isCompleted) started.complete();
    return gate.future;
  }
}

class GatedAssistantService extends AssistantService {
  GatedAssistantService(super.dio, super.demo);
  final started = Completer<void>();
  final gate = Completer<AssistantMessageModel>();
  @override
  Future<AssistantMessageModel> send(AssistantRequestPayload payload) {
    started.complete();
    return gate.future;
  }
}

class RacingBookingService extends BookingService {
  RacingBookingService(super.dio, super.demo);
  final gates = <DateTime, Completer<AvailabilityModel>>{};
  @override
  Future<AvailabilityModel> getAvailability(String serviceId, DateTime date) =>
      gates[date]?.future ?? super.getAvailability(serviceId, date);
}

class TimeoutAppointmentService extends AppointmentService {
  TimeoutAppointmentService(super.dio, super.demo);
  int calls = 0;
  @override
  Future<AppointmentModel> create(
    String userId,
    CreateBookingPayload payload,
  ) async {
    calls++;
    throw DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.receiveTimeout,
    );
  }
}

class RetryingAssistantService extends AssistantService {
  RetryingAssistantService(super.dio, super.demo);
  int calls = 0;
  @override
  Future<AssistantMessageModel> send(AssistantRequestPayload payload) async {
    if (++calls == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
    }
    return const AssistantMessageModel(
      id: 'reply',
      role: AssistantRole.assistant,
      text: 'Sample advice',
      actions: [
        AssistantAction(
          type: AssistantActionType.serviceDetails,
          serviceId: 'invented-id',
        ),
        AssistantAction(
          type: AssistantActionType.serviceDetails,
          serviceId: 'exterior-wash',
        ),
        AssistantAction(
          type: AssistantActionType.browseServices,
          categoryId: 'invented-category',
        ),
      ],
    );
  }
}
