import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/controller/logout_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_session.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_auth.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_services.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/controller/appointments_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/create_booking_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/service/appointment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/controller/assistant_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_message_model.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_request_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/service/assistant_service.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/controller/auth_form_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/model/auth_form_state.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/bookings/controller/my_bookings_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/bookings/model/my_bookings_state.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/controller/profile_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/model/update_profile_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';

import 'support/demo_container.dart';
import 'support/session_fakes.dart';

void main() {
  test(
    'an old history refresh cannot overwrite a newer mutation invalidation',
    () async {
      late DelayedAppointments service;
      final container = demoContainer(
        appointmentFactory: (dio, demo) =>
            service = DelayedAppointments(dio, demo),
      );
      await container.read(sessionProvider.future);
      container.listen(appointmentsControllerProvider, (_, _) {});
      final original = await container.read(
        appointmentsControllerProvider.future,
      );
      expect(original.items, isNotEmpty);
      final gate = Completer<List<AppointmentModel>>();
      service.gate = gate;
      final refresh = container
          .read(appointmentsControllerProvider.notifier)
          .refresh();
      service.gate = null;
      service.items = const [];
      container.invalidate(appointmentsControllerProvider);
      expect(
        (await container.read(appointmentsControllerProvider.future)).items,
        isEmpty,
      );
      gate.complete(original.items);
      await refresh;
      expect(
        container.read(appointmentsControllerProvider).requireValue.items,
        isEmpty,
      );
    },
  );

  test(
    'logout handles local storage failure, prevents duplicates, and allows retry',
    () async {
      final storage = MemoryTokenStorage('saved');
      final repository = CountingAuthRepository();
      final container = ProviderContainer.test(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repository),
          cookieTransportProvider.overrideWithValue(DemoCookieTransport()),
        ],
      );
      await container.read(sessionProvider.future);
      container.listen(logoutControllerProvider, (_, _) {});
      final controller = container.read(logoutControllerProvider.notifier);
      storage.clearError = StateError('storage unavailable');
      await Future.wait([controller.logout(), controller.logout()]);
      expect(repository.logoutCalls, 1);
      expect(container.read(logoutControllerProvider).loading, isFalse);
      expect(container.read(logoutControllerProvider).error, isNotNull);
      storage.clearError = null;
      await controller.logout();
      expect(repository.logoutCalls, 2);
      expect(container.read(logoutControllerProvider).error, isNull);
      expect(container.read(sessionIdentityProvider).userId, isNull);
    },
  );

  test(
    'profile save preserves pending AI responses, booking drafts, and history state',
    () async {
      late DelayedAssistant service;
      final container = demoContainer(
        assistantFactory: (dio, demo) => service = DelayedAssistant(dio, demo),
      );
      await container.read(sessionProvider.future);
      final identity = container.read(sessionIdentityProvider);
      container.listen(assistantControllerProvider, (_, _) {});
      container.listen(myBookingsTabProvider, (_, _) {});
      container.listen(profileControllerProvider, (_, _) {});
      container.listen(appointmentsControllerProvider, (_, _) {});
      final appointments = await container.read(
        appointmentsControllerProvider.future,
      );
      container
          .read(myBookingsTabProvider.notifier)
          .select(BookingsTab.previous);
      final booking = bookingControllerProvider('exterior-wash');
      container.listen(booking, (_, _) {});
      await container.read(booking.future);
      final controller = container.read(booking.notifier);
      await controller.selectDate(
        DemoWorkshop.today.add(const Duration(days: 3)),
      );
      final slot = container
          .read(booking)
          .requireValue
          .availability!
          .slots
          .firstWhere((slot) => slot.available);
      controller.selectSlot(slot.id);
      controller.review();
      container.read(assistantServiceProvider);
      final pending = container
          .read(assistantControllerProvider.notifier)
          .send('private question');
      await service.started.future;
      expect(
        await container
            .read(profileControllerProvider.notifier)
            .save(
              const UpdateProfilePayload(
                name: 'Updated',
                email: 'updated@example.com',
              ),
            ),
        isTrue,
      );
      expect(container.read(sessionIdentityProvider), identity);
      expect(
        container.read(appointmentsControllerProvider).requireValue,
        same(appointments),
      );
      expect(container.read(myBookingsTabProvider), BookingsTab.previous);
      expect(container.read(booking).requireValue.slotId, slot.id);
      expect(container.read(booking).requireValue.step, BookingStep.review);
      service.reply.complete(
        const AssistantMessageModel(
          id: 'reply',
          role: AssistantRole.assistant,
          text: 'Current account reply',
        ),
      );
      await pending;
      expect(container.read(assistantControllerProvider).sending, isFalse);
      expect(
        container.read(assistantControllerProvider).messages.last.id,
        'reply',
      );
    },
  );

  test(
    'refresh preserves valid review selection and clears a newly unavailable slot',
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
          .firstWhere((slot) => slot.available);
      controller.selectSlot(slot.id);
      controller.review();
      await controller.refreshAvailability();
      expect(container.read(provider).requireValue.slotId, slot.id);
      expect(container.read(provider).requireValue.step, BookingStep.review);
      await container
          .read(appointmentServiceProvider)
          .create(
            'another-driver',
            CreateBookingPayload(serviceId: 'exterior-wash', slotId: slot.id),
          );
      await controller.refreshAvailability();
      expect(container.read(provider).requireValue.slotId, isNull);
      expect(container.read(provider).requireValue.step, BookingStep.schedule);
      expect(container.read(provider).requireValue.canContinue, isFalse);
    },
  );

  test(
    'refresh coalesces requests and retains the review draft through a transient error',
    () async {
      late DelayedAvailability service;
      final container = demoContainer(
        bookingFactory: (dio, demo) => service = DelayedAvailability(dio, demo),
      );
      await container.read(sessionProvider.future);
      final provider = bookingControllerProvider('oil-change');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final controller = container.read(provider.notifier);
      await controller.selectDate(
        DemoWorkshop.today.add(const Duration(days: 1)),
      );
      final slot = container
          .read(provider)
          .requireValue
          .availability!
          .slots
          .firstWhere((slot) => slot.available);
      controller.selectSlot(slot.id);
      controller.review();
      service.gate = Completer<AvailabilityModel>();
      final calls = service.calls;
      final pending = controller.refreshAvailability();
      await controller.refreshAvailability();
      expect(service.calls, calls + 1);
      service.gate!.completeError(
        DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        ),
      );
      await pending;
      expect(container.read(provider).requireValue.slotId, slot.id);
      expect(container.read(provider).requireValue.step, BookingStep.review);
      expect(
        container.read(provider).requireValue.availabilityError,
        'RECEIVE_TIMEOUT',
      );
      expect(container.read(provider).requireValue.canContinue, isFalse);
      service.gate = null;
      await controller.refreshAvailability();
      expect(container.read(provider).requireValue.step, BookingStep.review);
      expect(container.read(provider).requireValue.canContinue, isTrue);
    },
  );

  test(
    'reauthentication to the same account discards a pending old AI response',
    () async {
      late DelayedAssistant service;
      final container = demoContainer(
        assistantFactory: (dio, demo) => service = DelayedAssistant(dio, demo),
      );
      await container.read(sessionProvider.future);
      container.listen(assistantControllerProvider, (_, _) {});
      final identity = container.read(sessionIdentityProvider);
      container.read(assistantServiceProvider);
      final pending = container
          .read(assistantControllerProvider.notifier)
          .send('old account');
      await service.started.future;
      await container
          .read(sessionProvider.notifier)
          .login(email: 'demo-driver', password: 'demo');
      expect(container.read(sessionIdentityProvider).userId, identity.userId);
      expect(container.read(sessionIdentityProvider), isNot(identity));
      service.reply.complete(
        const AssistantMessageModel(
          id: 'old',
          role: AssistantRole.assistant,
          text: 'Old response',
        ),
      );
      await pending;
      expect(container.read(assistantControllerProvider).messages, isEmpty);
      expect(container.read(assistantControllerProvider).sending, isFalse);
    },
  );

  test(
    'late route filter initialization cannot override a newer user search',
    () async {
      final container = demoContainer();
      final controller = container.read(homeControllerProvider.notifier);
      final pending = controller.browse('cleaning');
      controller.search('oil');
      await pending;
      expect(container.read(homeControllerProvider).query, 'oil');
      expect(container.read(homeControllerProvider).categoryId, isNull);
    },
  );

  for (final mode in AuthFormMode.values) {
    test(
      '$mode form validates, blocks duplicate requests, and exposes retryable errors',
      () async {
        final repository = CountingAuthRepository()
          ..authGate = Completer<AuthSession>();
        final container = ProviderContainer.test(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            authRepositoryProvider.overrideWithValue(repository),
            cookieTransportProvider.overrideWithValue(DemoCookieTransport()),
          ],
        );
        await container.read(sessionProvider.future);
        final provider = authFormControllerProvider(mode);
        container.listen(provider, (_, _) {});
        final controller = container.read(provider.notifier);
        await controller.submit(email: 'invalid', password: '');
        expect(repository.calls, 0);
        expect(container.read(provider).status, AuthFormStatus.failed);
        final pending = controller.submit(
          email: 'customer@example.com',
          password: 'password',
          name: 'Customer',
        );
        await controller.submit(
          email: 'customer@example.com',
          password: 'password',
          name: 'Customer',
        );
        await Future<void>.delayed(Duration.zero);
        expect(repository.calls, 1);
        expect(container.read(provider).submitting, isTrue);
        repository.authGate!.completeError(const InvalidCredentialsException());
        await pending;
        expect(
          container.read(provider).error,
          'The email or password is incorrect.',
        );
        repository.authGate = null;
        await controller.submit(
          email: 'customer@example.com',
          password: 'password',
          name: 'Customer',
        );
        expect(repository.calls, 2);
        expect(container.read(provider).status, AuthFormStatus.succeeded);
      },
    );
  }
}

class DelayedAssistant extends DemoAssistantService {
  DelayedAssistant(super.dio, super.workshop);
  final started = Completer<void>();
  final reply = Completer<AssistantMessageModel>();
  @override
  Future<AssistantMessageModel> send(AssistantRequestPayload payload) {
    started.complete();
    return reply.future;
  }
}

class DelayedAvailability extends DemoBookingService {
  DelayedAvailability(super.dio, super.workshop);
  Completer<AvailabilityModel>? gate;
  int calls = 0;
  @override
  Future<AvailabilityModel> getAvailability(String serviceId, DateTime date) {
    calls++;
    return gate?.future ?? super.getAvailability(serviceId, date);
  }
}

class CountingAuthRepository extends StubAuthRepository {
  int calls = 0;
  int logoutCalls = 0;
  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<AuthSession> login({required String email, required String password}) {
    calls++;
    return super.login(email: email, password: password);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) {
    calls++;
    return super.register(name: name, email: email, password: password);
  }
}

class DelayedAppointments extends DemoAppointmentService {
  DelayedAppointments(super.dio, super.workshop)
    : items = workshop.appointments('demo-driver');
  List<AppointmentModel> items;
  Completer<List<AppointmentModel>>? gate;
  @override
  Future<List<AppointmentModel>> getBookings(String userId) async =>
      gate == null ? items : gate!.future;
}
