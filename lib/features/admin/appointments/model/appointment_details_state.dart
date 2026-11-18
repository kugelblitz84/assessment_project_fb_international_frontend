import 'package:assessment_project_fb_international_frontend/features/admin/appointments/model/admin_appointment.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';

class AdminAppointmentDetailsState {
  AdminAppointmentDetailsState({
    required this.appointment,
    required List<BookingStatus> actions,
    required this.awaitingCompletion,
  }) : actions = List.unmodifiable(actions);
  final AdminAppointment appointment;
  final List<BookingStatus> actions;
  final bool awaitingCompletion;
}
