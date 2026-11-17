import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';

class AppointmentStatusPayload {
  const AppointmentStatusPayload(this.status);
  final BookingStatus status;
  Map<String, dynamic> toJson() => {'status': status.name};
}
