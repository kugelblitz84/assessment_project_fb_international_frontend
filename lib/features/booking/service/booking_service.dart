import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/backend_contract_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../shared/service/demo_workshop.dart';
import '../../shared/model/availability_model.dart';

final bookingServiceProvider = Provider(
  (ref) =>
      BookingService(ref.watch(dioProvider), ref.watch(demoWorkshopProvider)),
);

class BookingService {
  BookingService(this.dio, this.demo);
  final Dio dio;
  final DemoWorkshop? demo;
  DateTime get today {
    final local = DateTime.now();
    return demo != null
        ? DemoWorkshop.today
        : DateTime(local.year, local.month, local.day);
  }

  Future<AvailabilityModel> getAvailability(
    String serviceId,
    DateTime date,
  ) async {
    if (demo == null) throw const BackendContractException();
    await demo!.pause();
    return demo!.availability(serviceId, date);
  }
}
