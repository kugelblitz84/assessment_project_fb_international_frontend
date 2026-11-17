import '../network/api_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_provider.dart';
import '../network/request_access.dart';
import '../utils/workshop_calendar.dart';
import 'demo_mode.dart';

class BusinessHours {
  BusinessHours.fromJson(Map<String, dynamic> json)
    : dayOfWeek = json['dayOfWeek'] as int,
      opensAt = json['opensAt'] as String,
      closesAt = json['closesAt'] as String,
      isClosed = json['isClosed'] as bool;
  final int dayOfWeek;
  final String opensAt, closesAt;
  final bool isClosed;
}

class PlatformConfig {
  const PlatformConfig({
    required this.horizonDays,
    required this.slotStepMinutes,
    required this.timeZone,
    required this.settings,
    required this.businessHours,
    this.retrievedAt,
  });
  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map;
    final horizon = booking['horizonDays'] as int;
    final step = booking['slotStepMinutes'] as int;
    final zone = booking['timeZone'] as String;
    if (horizon < 1 ||
        horizon > 90 ||
        step < 5 ||
        step > 120 ||
        zone != WorkshopCalendar.timeZone) {
      throw const FormatException('Unsupported workshop configuration.');
    }
    return PlatformConfig(
      horizonDays: horizon,
      slotStepMinutes: step,
      timeZone: zone,
      retrievedAt: DateTime.now(),
      settings: Map.unmodifiable(json['settings'] as Map<String, dynamic>),
      businessHours: List.unmodifiable(
        (json['businessHours'] as List).map(
          (row) =>
              BusinessHours.fromJson(Map<String, dynamic>.from(row as Map)),
        ),
      ),
    );
  }
  final int horizonDays, slotStepMinutes;
  final String timeZone;
  final Map<String, dynamic> settings;
  final List<BusinessHours> businessHours;
  final DateTime? retrievedAt;
  bool get fresh =>
      retrievedAt == null ||
      DateTime.now().difference(retrievedAt!) < const Duration(minutes: 5);
  DateTime lastDate(DateTime today) =>
      WorkshopCalendar.lastDate(today, horizonDays: horizonDays);
  static const demo = PlatformConfig(
    horizonDays: 30,
    slotStepMinutes: 15,
    timeZone: 'Asia/Dhaka',
    settings: {},
    businessHours: [],
  );
}

final platformConfigServiceProvider = Provider(
  (ref) => PlatformConfigService(ref.watch(dioProvider)),
);

class PlatformConfigService {
  PlatformConfigService(this.dio);
  final Dio dio;
  Future<PlatformConfig> get() async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiEndpoints.platform,
      options: Options(extra: {requestAccessKey: RequestAccess.public}),
    );
    return PlatformConfig.fromJson(response.data!);
  }
}

final platformConfigProvider = FutureProvider.autoDispose<PlatformConfig>((
  ref,
) async {
  if (ref.watch(demoModeProvider)) return PlatformConfig.demo;
  final config = await ref.watch(platformConfigServiceProvider).get();
  // Config is revalidated on later visits rather than cached indefinitely.
  return config;
}, retry: (_, _) => null);
