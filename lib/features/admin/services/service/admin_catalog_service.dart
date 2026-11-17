import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/service_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/resource_activation_payload.dart';

final adminCatalogServiceProvider = Provider(
  (ref) => AdminCatalogService(ref.watch(dioProvider)),
);

class AdminCatalogService {
  AdminCatalogService(this._dio);
  final Dio _dio;
  Future<List<AdminService>> list() async => jsonList(
    (await _dio.get<Object?>(ApiEndpoints.adminServices)).data,
    AdminService.fromJson,
  );
  Future<AdminService> get(String id) async => decodeJson(
    (await _dio.get<Object?>(
      ApiEndpoints.resource(ApiEndpoints.adminServices, id),
    )).data,
    AdminService.fromJson,
  );
  Future<void> save(ServicePayload payload, {String? id}) async {
    if (id == null) {
      await _dio.post<Object?>(
        ApiEndpoints.adminServices,
        data: payload.toJson(),
      );
    } else {
      await _dio.patch<Object?>(
        ApiEndpoints.resource(ApiEndpoints.adminServices, id),
        data: payload.toJson(),
      );
    }
  }

  Future<void> setActive(String id, bool active) async {
    await _dio.patch<Object?>(
      ApiEndpoints.resource(ApiEndpoints.adminServices, id),
      data: ResourceActivationPayload(active).toJson(),
    );
  }
}
