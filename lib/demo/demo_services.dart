import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/create_booking_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/service/appointment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_message_model.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_request_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/service/assistant_service.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/service/booking_service.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/service_catalog_service.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/service/payment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/model/update_profile_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/service/profile_service.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';

class DemoCatalogService extends ServiceCatalogService {
  DemoCatalogService(super.dio, this.workshop);
  final DemoWorkshop workshop;
  @override
  Future<List<ServiceModel>> getServices() async {
    await workshop.pause();
    return DemoWorkshop.services;
  }

  @override
  Future<ServiceModel> getService(String id) async {
    await workshop.pause();
    return DemoWorkshop.services.firstWhere(
      (service) => service.id == id,
      orElse: () => throw const ApiFailure('NOT_FOUND'),
    );
  }
}

class DemoBookingService extends BookingService {
  DemoBookingService(super.dio, this.workshop);
  final DemoWorkshop workshop;
  @override
  DateTime get today => DemoWorkshop.today;
  @override
  Future<AvailabilityModel> getAvailability(
    String serviceId,
    DateTime date,
  ) async {
    await workshop.pause();
    return workshop.availability(serviceId, date);
  }
}

class DemoAppointmentService extends AppointmentService {
  DemoAppointmentService(super.dio, this.workshop);
  final DemoWorkshop workshop;
  @override
  Future<List<AppointmentModel>> getBookings(String userId) async {
    await workshop.pause();
    return workshop.appointments(userId);
  }

  @override
  Future<AppointmentModel> getBooking(String userId, String id) async {
    await workshop.pause();
    return workshop.appointment(userId, id) ??
        (throw const ApiFailure('NOT_FOUND'));
  }

  @override
  Future<AppointmentModel> create(
    String userId,
    CreateBookingPayload payload,
  ) async {
    await workshop.pause();
    return workshop.create(userId, payload.serviceId, payload.slotId) ??
        (throw const ApiFailure('CONFLICT'));
  }

  @override
  Future<AppointmentModel> cancel(String userId, String id) async {
    await workshop.pause();
    return workshop.cancel(userId, id) ?? (throw const ApiFailure('CONFLICT'));
  }
}

class DemoAssistantService extends AssistantService {
  DemoAssistantService(super.dio, this.workshop);
  final DemoWorkshop workshop;
  @override
  Future<AssistantMessageModel> send(AssistantRequestPayload payload) async {
    await workshop.pause();
    final prompt = payload.messages.last.text.toLowerCase();
    final ids = switch (prompt) {
      _ when prompt.contains('wash') || prompt.contains('clean') => [
        'exterior-wash',
        'interior-detail',
      ],
      _ when prompt.contains('trip') || prompt.contains('safe') => [
        'tyre-inspection',
        'battery-check',
        'oil-change',
      ],
      _ when prompt.contains('battery') => ['battery-check'],
      _ when prompt.contains('oil') || prompt.contains('engine') => [
        'oil-change',
      ],
      _ when prompt.contains('budget') || prompt.contains('price') => [
        'battery-check',
        'tyre-inspection',
        'exterior-wash',
      ],
      _ when prompt.contains('ac') || prompt.contains('cool') => [
        'ac-inspection',
      ],
      _ => ['exterior-wash', 'oil-change', 'tyre-inspection'],
    };
    final message = prompt.contains('wash')
        ? 'An exterior wash includes a foam wash, wheel and tyre cleaning, and a microfibre hand dry. For the cabin, take a look at interior detailing. Open a service below for its sample price and inclusions.'
        : 'Here are a few services from the sample catalogue that may be useful. Open a card to compare its price, duration and inclusions. For warning lights, unusual noises or safety concerns, arrange a technician’s inspection before deciding on a repair.';
    return AssistantMessageModel(
      id: 'reply-${DateTime.now().microsecondsSinceEpoch}',
      role: AssistantRole.assistant,
      text: message,
      actions: [
        for (final id in ids)
          AssistantAction(
            type: AssistantActionType.serviceDetails,
            serviceId: id,
          ),
        const AssistantAction(type: AssistantActionType.browseServices),
      ],
    );
  }
}

class DemoProfileService extends ProfileService {
  DemoProfileService(super.dio, this.workshop);
  final DemoWorkshop workshop;
  @override
  Future<UserEntity> update(String userId, UpdateProfilePayload payload) async {
    await workshop.pause();
    return UserEntity(id: userId, name: payload.name, email: payload.email);
  }
}

class DemoPaymentService extends PaymentService {
  DemoPaymentService(super.dio);
  @override
  Future<PaymentConfig> config() async => PaymentConfig.demo;
  @override
  Future<List<PaymentAttempt>> history(String id) async => const [];
  @override
  Future<PaymentAttempt> get(String id) async =>
      throw const ApiFailure('NOT_FOUND');
  @override
  Future<PaymentAttempt> initiate(String id, CheckoutContact contact) async =>
      throw const ApiFailure('PAYMENTS_DISABLED');
  @override
  Future<PaymentAttempt> reconcile(String id) async =>
      throw const ApiFailure('PAYMENTS_DISABLED');
}
