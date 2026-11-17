import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/network/transport_timeouts.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';

final paymentServiceProvider = Provider(
  (ref) => PaymentService(ref.watch(dioProvider)),
);

class PaymentService {
  PaymentService(Dio dio) : _dio = dio;
  final Dio _dio;
  Future<PaymentConfig> config() async => decodeJson(
    (await _dio.get<Object?>(
      ApiEndpoints.paymentConfig,
      options: Options(extra: {requestAccessKey: RequestAccess.public}),
    )).data,
    PaymentConfig.fromJson,
  );
  Future<List<PaymentAttempt>> history(String id) async => jsonList(
    (await _dio.get<Object?>(ApiEndpoints.appointmentPayments(id))).data,
    PaymentAttempt.fromJson,
  );
  Future<PaymentAttempt> get(String id) async => decodeJson(
    (await _dio.get<Object?>(
      ApiEndpoints.resource(ApiEndpoints.payments, id),
    )).data,
    PaymentAttempt.fromJson,
  );
  Future<PaymentAttempt> initiate(String id, CheckoutContact contact) async =>
      decodeJson(
        (await _dio.post<Object?>(
          ApiEndpoints.payAppointment(id),
          data: contact.toJson(),
          options: Options(receiveTimeout: TransportTimeouts.longReceive),
        )).data,
        PaymentAttempt.fromJson,
      );
  Future<PaymentAttempt> reconcile(String id) async => decodeJson(
    (await _dio.post<Object?>(
      ApiEndpoints.reconcilePayment(id),
      options: Options(receiveTimeout: TransportTimeouts.longReceive),
    )).data,
    PaymentAttempt.fromJson,
  );
}
