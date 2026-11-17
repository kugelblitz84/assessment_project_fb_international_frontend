import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/model/admin_dashboard.dart';

final adminDashboardServiceProvider = Provider(
  (ref) => AdminDashboardService(ref.watch(dioProvider)),
);

class AdminDashboardService {
  AdminDashboardService(this._dio);
  final Dio _dio;
  Future<AdminDashboard> get() async => decodeJson(
    (await _dio.get<Object?>(ApiEndpoints.adminDashboard)).data,
    AdminDashboard.fromJson,
  );
}
