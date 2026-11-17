import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/transport_timeouts.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/model/selected_image.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/model/uploaded_image.dart';

final adminImageServiceProvider = Provider(
  (ref) => AdminImageService(ref.watch(dioProvider)),
);

class AdminImageService {
  AdminImageService(this._dio);
  final Dio _dio;
  FormData _imageRequest(SelectedImage image) {
    return FormData.fromMap({
      'file': MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
        contentType: DioMediaType('image', image.mimeSubtype),
      ),
    });
  }

  Future<String> upload(SelectedImage image) async {
    final response = await _dio.post<Object?>(
      ApiEndpoints.adminImages,
      data: _imageRequest(image),
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: TransportTimeouts.longReceive,
        sendTimeout: TransportTimeouts.uploadSend,
      ),
    );
    return decodeJson(response.data, UploadedImage.fromJson).url;
  }
}
