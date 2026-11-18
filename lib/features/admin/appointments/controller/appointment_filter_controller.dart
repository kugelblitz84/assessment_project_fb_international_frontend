import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/features/admin/appointments/model/appointment_filter_state.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_time.dart';

final appointmentFilterProvider = NotifierProvider.autoDispose
    .family<AppointmentFilterController, AppointmentFilterState, String?>(
      AppointmentFilterController.new,
    );

class AppointmentFilterController extends Notifier<AppointmentFilterState> {
  AppointmentFilterController(this.initialStatus);
  final String? initialStatus;
  @override
  AppointmentFilterState build() {
    ref.watch(adminOwnerProvider);
    return AppointmentFilterState(status: _status(initialStatus));
  }

  String _status(String? value) =>
      BookingStatus.values.any((s) => s.name == value) ? value! : '';
  DateTime get pickerInitialDate =>
      state.date ?? WorkshopTime.local(DateTime.now());
  void selectStatus(String? value) =>
      state = AppointmentFilterState(status: _status(value), date: state.date);
  void selectDate(DateTime? value) {
    if (!ref.mounted) return;
    state = AppointmentFilterState(status: state.status, date: value);
  }
}
