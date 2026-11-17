import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_summary.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';

enum BookingStatus { pending, confirmed, cancelled, completed }

class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.slot,
    required this.status,
    required this.price,
    required this.currency,
    required this.durationMinutes,
    this.originalPrice,
    this.canCancel = false,
    this.paymentStatus = PaymentSummary.unpaid,
    this.paymentMethod,
    this.canPayOnline = false,
  });
  final String id;
  final String serviceId;
  final String serviceName;
  final TimeSlotModel slot;
  final BookingStatus status;
  final num price;
  final String currency;
  final int durationMinutes;
  final num? originalPrice;
  final bool canCancel;
  final PaymentSummary paymentStatus;
  final String? paymentMethod;
  final bool canPayOnline;
  bool get upcoming =>
      (status == BookingStatus.pending || status == BookingStatus.confirmed) &&
      slot.startsAt.isAfter(DateTime.now());

  AppointmentModel copyWith({BookingStatus? status}) => AppointmentModel(
    id: id,
    serviceId: serviceId,
    serviceName: serviceName,
    slot: slot,
    status: status ?? this.status,
    price: price,
    currency: currency,
    durationMinutes: durationMinutes,
    originalPrice: originalPrice,
    canCancel: status != null && status != this.status ? false : canCancel,
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    canPayOnline: canPayOnline,
  );

  factory AppointmentModel.fromJson(Map<String, dynamic> json) =>
      AppointmentModel(
        id: json['id'] as String,
        serviceId: json['serviceId'] as String,
        serviceName: json['serviceName'] as String,
        slot: TimeSlotModel.fromJson(json['slot'] as Map<String, dynamic>),
        status: BookingStatus.values.byName(json['status'] as String),
        price: json['price'] as num,
        currency: json['currency'] as String,
        durationMinutes: json['durationMinutes'] as int,
        originalPrice: json['originalPrice'] as num?,
        canCancel: _readCanCancel(json),
        paymentStatus: PaymentSummary.parse(json['paymentStatus'] as String),
        paymentMethod: paymentMethodFromJson(json['paymentMethod']),
        canPayOnline: json['canPayOnline'] as bool,
      );

  static bool _readCanCancel(Map<String, dynamic> json) {
    if (json['canCancel'] is! bool) {
      throw const FormatException('Missing cancellation eligibility.');
    }
    return json['canCancel'] as bool;
  }
}
