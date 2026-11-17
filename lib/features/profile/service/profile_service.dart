import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/session/data/user_model.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/session/domain/user_entity.dart';
import '../../shared/service/demo_workshop.dart';
import '../model/update_profile_payload.dart';

final profileServiceProvider = Provider(
  (ref) =>
      ProfileService(ref.watch(dioProvider), ref.watch(demoWorkshopProvider)),
);

class ProfileService {
  ProfileService(this.dio, this.demo);
  final Dio dio;
  final DemoWorkshop? demo;
  Future<UserEntity> update(String userId, UpdateProfilePayload payload) async {
    if (demo == null) {
      final response = await dio.patch<Map<String, dynamic>>(
        ApiEndpoints.profile,
        data: payload.toJson(),
      );
      return UserModel.fromJson(response.data!['user'] as Map<String, dynamic>);
    }
    await demo!.pause();
    return UserEntity(id: userId, name: payload.name, email: payload.email);
  }
}
