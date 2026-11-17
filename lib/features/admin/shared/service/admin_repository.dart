import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../model/admin_models.dart';

final adminRepositoryProvider = Provider(
  (ref) => AdminRepository(ref.watch(dioProvider)),
);

class AdminRepository {
  AdminRepository(this.dio);
  final Dio dio;
  Future<Json> get(String path) async =>
      Map<String, dynamic>.from((await dio.get<Object?>(path)).data as Map);
  Future<Json> reconcilePayment(String id) async => Map<String, dynamic>.from(
    (await dio.post<Object?>(
          ApiEndpoints.reconcilePayment(id, admin: true),
        )).data
        as Map,
  );
  Future<List<T>> list<T>(
    String path,
    T Function(Json) decode, {
    Json? query,
  }) async {
    final response = await dio.get<Object?>(path, queryParameters: query);
    return List.unmodifiable(
      (response.data as List).map(
        (row) => decode(Map<String, dynamic>.from(row as Map)),
      ),
    );
  }

  Future<void> save(String path, Json payload, {String? id}) async {
    if (id == null) {
      await dio.post<Object?>(path, data: payload);
    } else {
      await dio.patch<Object?>(ApiEndpoints.resource(path, id), data: payload);
    }
  }

  Future<void> transition(String id, String status) async {
    await dio.patch<Object?>(
      ApiEndpoints.adminAppointmentStatus(id),
      data: {'status': status},
    );
  }

  static const maxImageBytes = 2 * 1024 * 1024;
  static FormData imageRequest(Uint8List bytes, String filename) {
    if (bytes.isEmpty || bytes.length > maxImageBytes) {
      throw const FormatException('Invalid image size.');
    }
    final extension = filename.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'jpg' || 'jpeg' => 'jpeg',
      'png' => 'png',
      'webp' => 'webp',
      _ => null,
    };
    if (mime == null) throw const FormatException('Unsupported image.');
    return FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType('image', mime),
      ),
    });
  }

  Future<String> upload(Uint8List bytes, String filename) async {
    final response = await dio.post<Object?>(
      ApiEndpoints.adminImages,
      data: imageRequest(bytes, filename),
      options: Options(contentType: 'multipart/form-data'),
    );
    final url = (response.data as Map)['imageUrl'] as String;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !{'https', 'http'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const FormatException('Invalid media URL.');
    }
    return url;
  }
}
