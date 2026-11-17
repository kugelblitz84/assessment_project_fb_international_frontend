import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/create_booking_payload.dart';

final appointmentServiceProvider = Provider(
  (ref) => AppointmentService(ref.watch(dioProvider)),
);

class AppointmentService {
  AppointmentService(Dio dio) : _dio = dio;
  final Dio _dio;
  // userId supplies local ownership context to demo/test implementations.
  // Live ownership is derived exclusively from the authenticated backend session.
  Future<List<AppointmentModel>> getBookings(String userId) async => jsonList(
    (await _dio.get<Object?>(ApiEndpoints.appointments)).data,
    AppointmentModel.fromJson,
  );
  Future<AppointmentModel> getBooking(String userId, String id) async =>
      decodeJson(
        (await _dio.get<Object?>(
          ApiEndpoints.resource(ApiEndpoints.appointments, id),
        )).data,
        AppointmentModel.fromJson,
      );
  Future<AppointmentModel> create(
    String userId,
    CreateBookingPayload payload,
  ) async => decodeJson(
    (await _dio.post<Object?>(
      ApiEndpoints.appointments,
      data: payload.toJson(),
    )).data,
    AppointmentModel.fromJson,
  );
  Future<AppointmentModel> cancel(String userId, String id) async => decodeJson(
    (await _dio.patch<Object?>(ApiEndpoints.cancelAppointment(id))).data,
    AppointmentModel.fromJson,
  );
}
