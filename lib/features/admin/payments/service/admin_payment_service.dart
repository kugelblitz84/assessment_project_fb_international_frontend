import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/transport_timeouts.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';

final adminPaymentServiceProvider = Provider(
  (ref) => AdminPaymentService(ref.watch(dioProvider)),
);

class AdminPaymentService {
  AdminPaymentService(this._dio);
  final Dio _dio;
  Future<List<AdminPayment>> list({String? status}) async => jsonList(
    (await _dio.get<Object?>(
      ApiEndpoints.adminPayments,
      queryParameters: {'status': ?status},
    )).data,
    AdminPayment.fromJson,
  );
  Future<AdminPayment> get(String id) async => decodeJson(
    (await _dio.get<Object?>(
      ApiEndpoints.resource(ApiEndpoints.adminPayments, id),
    )).data,
    AdminPayment.fromJson,
  );
  Future<AdminPayment> reconcile(String id) async => decodeJson(
    (await _dio.post<Object?>(
      ApiEndpoints.reconcilePayment(id, admin: true),
      options: Options(receiveTimeout: TransportTimeouts.longReceive),
    )).data,
    AdminPayment.fromJson,
  );
}
