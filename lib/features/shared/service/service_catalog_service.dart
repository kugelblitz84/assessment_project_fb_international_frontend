import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/backend_contract_exception.dart';
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
    if (demo == null) throw const BackendContractException();
    await demo!.pause();
    return DemoWorkshop.services;
  }
}
