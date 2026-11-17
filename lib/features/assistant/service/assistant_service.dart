import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/network/transport_timeouts.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_message_model.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_request_payload.dart';

final assistantServiceProvider = Provider(
  (ref) => AssistantService(ref.watch(dioProvider)),
);

class AssistantService {
  AssistantService(Dio dio) : _dio = dio;
  final Dio _dio;
  Future<AssistantMessageModel> send(AssistantRequestPayload payload) async {
    final response = await _dio.post<Object?>(
      ApiEndpoints.assistantChat,
      data: payload.toJson(),
      options: Options(
        extra: {requestAccessKey: RequestAccess.optional},
        receiveTimeout: TransportTimeouts.longReceive,
      ),
    );
    return decodeJson(response.data, AssistantMessageModel.fromJson);
  }
}
