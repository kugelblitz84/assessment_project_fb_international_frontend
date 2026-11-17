import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';

final serviceCatalogProvider = Provider(
  (ref) => ServiceCatalogService(ref.watch(dioProvider)),
);

class ServiceCatalogService {
  ServiceCatalogService(Dio dio) : _dio = dio;
  final Dio _dio;
  Future<List<ServiceModel>> getServices() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.services,
      options: Options(extra: {requestAccessKey: RequestAccess.public}),
    );
    return jsonList(response.data, ServiceModel.fromJson);
  }

  Future<ServiceModel> getService(String id) async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.resource(ApiEndpoints.services, id),
      options: Options(extra: {requestAccessKey: RequestAccess.public}),
    );
    return decodeJson(response.data, ServiceModel.fromJson);
  }
}
