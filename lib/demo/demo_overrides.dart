import 'package:riverpod/misc.dart';

import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_services.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/service/appointment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/service/assistant_service.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/service/booking_service.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/service_catalog_service.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/service/payment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/service/profile_service.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/controller/platform_config_provider.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/platform_config.dart';

/// Only explicit demo composition selects fixture implementations. Production
/// services never import demo behavior or turn failures into sample data.
List<Override> demoServiceOverrides() => [
  platformConfigProvider.overrideWith((ref) async => PlatformConfig.demo),
  serviceCatalogProvider.overrideWith(
    (ref) => DemoCatalogService(
      ref.watch(dioProvider),
      ref.watch(demoWorkshopProvider)!,
    ),
  ),
  bookingServiceProvider.overrideWith(
    (ref) => DemoBookingService(
      ref.watch(dioProvider),
      ref.watch(demoWorkshopProvider)!,
    ),
  ),
  appointmentServiceProvider.overrideWith(
    (ref) => DemoAppointmentService(
      ref.watch(dioProvider),
      ref.watch(demoWorkshopProvider)!,
    ),
  ),
  assistantServiceProvider.overrideWith(
    (ref) => DemoAssistantService(
      ref.watch(dioProvider),
      ref.watch(demoWorkshopProvider)!,
    ),
  ),
  profileServiceProvider.overrideWith(
    (ref) => DemoProfileService(
      ref.watch(dioProvider),
      ref.watch(demoWorkshopProvider)!,
    ),
  ),
  paymentServiceProvider.overrideWith(
    (ref) => DemoPaymentService(ref.watch(dioProvider)),
  ),
];
