import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/request_access.dart';
import '../../../core/utils/workshop_calendar.dart';
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
    return demo != null ? DemoWorkshop.today : WorkshopCalendar.today();
  }

  Future<AvailabilityModel> getAvailability(
    String serviceId,
    DateTime date,
  ) async {
    if (demo == null) {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.availability(serviceId),
        queryParameters: {'date': WorkshopCalendar.dateText(date)},
        options: Options(extra: {requestAccessKey: RequestAccess.public}),
      );
      return AvailabilityModel.fromJson(response.data!);
    }
    await demo!.pause();
    return demo!.availability(serviceId, date);
  }
}
