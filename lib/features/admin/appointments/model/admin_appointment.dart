import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_summary.dart';

class AdminAppointment {
  AdminAppointment.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      serviceName = json['serviceName'] as String,
      customerName = (json['user'] as Map)['name'] as String,
      customerEmail = (json['user'] as Map)['email'] as String,
      startsAt = DateTime.parse(json['startsAt'] as String),
      endsAt = DateTime.parse(json['endsAt'] as String),
      status = BookingStatus.values.byName(json['status'] as String),
      price = json['price'] as num,
      basePrice = json['basePrice'] as num,
      currency = json['currency'] as String,
      durationMinutes = json['durationMinutes'] as int,
      createdAt = DateTime.parse(json['createdAt'] as String),
      cancelledAt = json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      vehicle = json['vehicle'] == null
          ? null
          : Map<String, dynamic>.from(json['vehicle'] as Map),
      appliedOfferId = json['appliedOfferId'] as String?,
      paymentStatus = PaymentSummary.parse(json['paymentStatus'] as String),
      paymentMethod = paymentMethodFromJson(json['paymentMethod']),
      canPayOnline = json['canPayOnline'] as bool,
      canCancel = json['canCancel'] as bool;
  final PaymentSummary paymentStatus;
  final String? paymentMethod;
  final bool canPayOnline, canCancel;
  final String id, serviceName, customerName, customerEmail, currency;
  final BookingStatus status;
  final DateTime startsAt, endsAt, createdAt;
  final DateTime? cancelledAt;
  final num price, basePrice;
  final int durationMinutes;
  final Map<String, dynamic>? vehicle;
  final String? appliedOfferId;
  List<BookingStatus> actionsAt(DateTime now) =>
      paymentStatus == PaymentSummary.reviewRequired
      ? []
      : switch (status) {
          BookingStatus.pending => [
            BookingStatus.confirmed,
            if (canCancel) BookingStatus.cancelled,
          ],
          BookingStatus.confirmed => [
            if (!now.isBefore(endsAt)) BookingStatus.completed,
            if (canCancel) BookingStatus.cancelled,
          ],
          _ => [],
        };
}
