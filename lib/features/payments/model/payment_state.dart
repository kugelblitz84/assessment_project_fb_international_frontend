import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';

class PaymentState {
  const PaymentState({
    required this.appointment,
    required this.attempts,
    this.busy = false,
    this.uncertain = false,
    this.errorCode,
  });
  final AppointmentModel appointment;
  final List<PaymentAttempt> attempts;
  final bool busy, uncertain;
  final String? errorCode;
  PaymentState copyWith({
    bool? busy,
    bool? uncertain,
    String? errorCode,
    bool clearError = false,
  }) => PaymentState(
    appointment: appointment,
    attempts: attempts,
    busy: busy ?? this.busy,
    uncertain: uncertain ?? this.uncertain,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );
  bool get hasUnresolved =>
      attempts.any((p) => p.status.unresolved || p.applied);
}
