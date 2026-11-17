import 'availability_model.dart';

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
  });
  final String id;
  final String serviceId;
  final String serviceName;
  final TimeSlotModel slot;
  final BookingStatus status;
  final num price;
  final String currency;
  final int durationMinutes;

  bool get canCancel => status == BookingStatus.pending;
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
      );
}
