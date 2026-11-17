import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/model/admin_appointment.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/model/appointment_status_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';

final adminAppointmentServiceProvider = Provider(
  (ref) => AdminAppointmentService(ref.watch(dioProvider)),
);

class AdminAppointmentService {
  AdminAppointmentService(this._dio);
  final Dio _dio;
  Future<List<AdminAppointment>> list({String? status, String? date}) async =>
      jsonList(
        (await _dio.get<Object?>(
          ApiEndpoints.adminAppointments,
          queryParameters: {'status': ?status, 'date': ?date},
        )).data,
        AdminAppointment.fromJson,
      );
  Future<AdminAppointment> get(String id) async => decodeJson(
    (await _dio.get<Object?>(
      ApiEndpoints.resource(ApiEndpoints.adminAppointments, id),
    )).data,
    AdminAppointment.fromJson,
  );
  Future<void> transition(String id, BookingStatus status) async {
    await _dio.patch<Object?>(
      ApiEndpoints.adminAppointmentStatus(id),
      data: AppointmentStatusPayload(status).toJson(),
    );
  }
}
