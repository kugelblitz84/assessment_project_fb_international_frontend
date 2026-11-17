import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/user_model.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/model/update_profile_payload.dart';

final profileServiceProvider = Provider(
  (ref) => ProfileService(ref.watch(dioProvider)),
);

class ProfileService {
  ProfileService(Dio dio) : _dio = dio;
  final Dio _dio;
  Future<UserEntity> update(String userId, UpdateProfilePayload payload) async {
    final response = await _dio.patch<Object?>(
      ApiEndpoints.profile,
      data: payload.toJson(),
    );
    return decodeJson(jsonObject(response.data)['user'], UserModel.fromJson);
  }
}
