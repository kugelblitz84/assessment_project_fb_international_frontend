import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_calendar.dart';

final bookingServiceProvider = Provider(
  (ref) => BookingService(ref.watch(dioProvider)),
);

class BookingService {
  BookingService(Dio dio) : _dio = dio;
  final Dio _dio;
  DateTime get today => WorkshopCalendar.today();
  Future<AvailabilityModel> getAvailability(
    String serviceId,
    DateTime date,
  ) async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.availability(serviceId),
      queryParameters: {'date': WorkshopCalendar.dateText(date)},
      options: Options(extra: {requestAccessKey: RequestAccess.public}),
    );
    return decodeJson(response.data, AvailabilityModel.fromJson);
  }
}
