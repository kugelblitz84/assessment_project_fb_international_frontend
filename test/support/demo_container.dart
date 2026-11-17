import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_auth.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/service/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/service/booking_service.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/service/assistant_service.dart';
import 'package:assessment_project_fb_international_frontend/features/shared/service/appointment_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FastDemoWorkshop extends DemoWorkshop {
  @override
  Future<void> pause() async {}
}

ProviderContainer demoContainer({
  bool authenticated = true,
  bool demoData = true,
  BookingService Function(Dio, DemoWorkshop?)? bookingFactory,
  AppointmentService Function(Dio, DemoWorkshop?)? appointmentFactory,
  AssistantService Function(Dio, DemoWorkshop?)? assistantFactory,
}) => ProviderContainer.test(
  overrides: [
    demoModeProvider.overrideWithValue(demoData),
    demoWorkshopProvider.overrideWithValue(
      demoData ? FastDemoWorkshop() : null,
    ),
    if (bookingFactory != null)
      bookingServiceProvider.overrideWith(
        (ref) => bookingFactory(
          ref.watch(dioProvider),
          ref.watch(demoWorkshopProvider),
        ),
      ),
    if (appointmentFactory != null)
      appointmentServiceProvider.overrideWith(
        (ref) => appointmentFactory(
          ref.watch(dioProvider),
          ref.watch(demoWorkshopProvider),
        ),
      ),
    if (assistantFactory != null)
      assistantServiceProvider.overrideWith(
        (ref) => assistantFactory(
          ref.watch(dioProvider),
          ref.watch(demoWorkshopProvider),
        ),
      ),
    tokenStorageProvider.overrideWithValue(
      DemoTokenStorage()..token = authenticated ? 'demo-token' : null,
    ),
    authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
    cookieTransportProvider.overrideWithValue(DemoCookieTransport()),
  ],
);
