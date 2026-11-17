import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/request_access.dart';
import '../../../core/network/dio_provider.dart';
import '../model/service_model.dart';
import 'demo_workshop.dart';

final serviceCatalogProvider = Provider(
  (ref) => ServiceCatalogService(
    ref.watch(dioProvider),
    ref.watch(demoWorkshopProvider),
  ),
);

class ServiceCatalogService {
  ServiceCatalogService(this.dio, this.demo);
  final Dio dio;
  final DemoWorkshop? demo;

  Future<List<ServiceModel>> getServices() async {
    if (demo == null) {
      final response = await dio.get<Object?>(
        ApiEndpoints.services,
        options: Options(extra: {requestAccessKey: RequestAccess.public}),
      );
      final json = response.data;
      if (json is! List) {
        throw const FormatException('Invalid catalog response.');
      }
      return List.unmodifiable(
        json.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid catalog service.');
          }
          return ServiceModel.fromJson(item);
        }),
      );
    }
    await demo!.pause();
    return DemoWorkshop.services;
  }
}
