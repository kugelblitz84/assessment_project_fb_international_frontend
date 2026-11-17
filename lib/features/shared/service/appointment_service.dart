import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/backend_contract_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../model/create_booking_payload.dart';
import '../model/appointment_model.dart';
import 'demo_workshop.dart';

final appointmentServiceProvider = Provider(
  (ref) => AppointmentService(
    ref.watch(dioProvider),
    ref.watch(demoWorkshopProvider),
  ),
);

class AppointmentService {
  AppointmentService(this.dio, this.demo);
  final Dio dio;
  final DemoWorkshop? demo;

  Future<List<AppointmentModel>> getBookings(String userId) async {
    if (demo == null) throw const BackendContractException();
    await demo!.pause();
    return demo!.appointments(userId);
  }

  Future<AppointmentModel> getBooking(String userId, String id) async {
    if (demo == null) throw const BackendContractException();
    await demo!.pause();
    return demo!.appointment(userId, id) ?? (throw _failure(404));
  }

  Future<AppointmentModel> create(
    String userId,
    CreateBookingPayload payload,
  ) async {
    if (demo == null) throw const BackendContractException();
    await demo!.pause();
    return demo!.create(userId, payload.serviceId, payload.slotId) ??
        (throw _failure(409));
  }

  Future<AppointmentModel> cancel(String userId, String id) async {
    if (demo == null) throw const BackendContractException();
    await demo!.pause();
    return demo!.cancel(userId, id) ?? (throw _failure(409));
  }

  // Demo failures exercise the same central HTTP mapping as the future API.
  DioException _failure(int status) {
    final request = RequestOptions(path: 'demo://appointments');
    return DioException.badResponse(
      statusCode: status,
      requestOptions: request,
      response: Response<Object?>(requestOptions: request, statusCode: status),
    );
  }
}
