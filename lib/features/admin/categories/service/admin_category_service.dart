import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/admin_category.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/category_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/resource_activation_payload.dart';

final adminCategoryServiceProvider = Provider(
  (ref) => AdminCategoryService(ref.watch(dioProvider)),
);

class AdminCategoryService {
  AdminCategoryService(this._dio);
  final Dio _dio;
  Future<List<AdminCategory>> list() async => jsonList(
    (await _dio.get<Object?>(ApiEndpoints.adminCategories)).data,
    AdminCategory.fromJson,
  );
  Future<AdminCategory> get(String id) async => decodeJson(
    (await _dio.get<Object?>(
      ApiEndpoints.resource(ApiEndpoints.adminCategories, id),
    )).data,
    AdminCategory.fromJson,
  );
  Future<void> save(CategoryPayload payload, {String? id}) async {
    if (id == null) {
      await _dio.post<Object?>(
        ApiEndpoints.adminCategories,
        data: payload.toJson(),
      );
    } else {
      await _dio.patch<Object?>(
        ApiEndpoints.resource(ApiEndpoints.adminCategories, id),
        data: payload.toJson(),
      );
    }
  }

  Future<void> setActive(String id, bool active) async {
    await _dio.patch<Object?>(
      ApiEndpoints.resource(ApiEndpoints.adminCategories, id),
      data: ResourceActivationPayload(active).toJson(),
    );
  }
}
