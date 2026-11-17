import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';

class AppointmentsState {
  const AppointmentsState({
    required this.ownerId,
    this.items = const [],
    this.refreshing = false,
    this.errorCode,
  });
  final String? ownerId;
  final List<AppointmentModel> items;
  final bool refreshing;
  final String? errorCode;
  AppointmentsState copyWith({
    List<AppointmentModel>? items,
    bool? refreshing,
    String? errorCode,
    bool clearError = false,
  }) => AppointmentsState(
    ownerId: ownerId,
    items: items ?? this.items,
    refreshing: refreshing ?? this.refreshing,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );
}

class AppointmentDetailsState {
  const AppointmentDetailsState({
    required this.ownerId,
    this.appointment,
    this.busy = false,
    this.errorCode,
  });
  final String? ownerId;
  final AppointmentModel? appointment;
  final bool busy;
  final String? errorCode;
  AppointmentDetailsState copyWith({
    AppointmentModel? appointment,
    bool? busy,
    String? errorCode,
    bool clearError = false,
  }) => AppointmentDetailsState(
    ownerId: ownerId,
    appointment: appointment ?? this.appointment,
    busy: busy ?? this.busy,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );
}
