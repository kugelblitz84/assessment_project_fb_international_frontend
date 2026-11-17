import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/platform_config.dart';

final platformConfigServiceProvider = Provider(
  (ref) => PlatformConfigService(ref.watch(dioProvider)),
);

class PlatformConfigService {
  PlatformConfigService(this._dio);
  final Dio _dio;
  Future<PlatformConfig> get() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.platform,
      options: Options(extra: {requestAccessKey: RequestAccess.public}),
    );
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid workshop configuration.');
    }
    return decodeJson(json, PlatformConfig.fromJson);
  }
}
