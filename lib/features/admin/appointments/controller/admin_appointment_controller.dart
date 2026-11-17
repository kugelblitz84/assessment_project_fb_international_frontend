import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/model/admin_appointment.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/service/admin_appointment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/controller/admin_dashboard_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/controller/appointments_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';

typedef AppointmentFilter = ({String? status, String? date});
typedef AdminAppointmentKey = ({AdminOwner owner, AppointmentFilter filter});
final adminAppointmentsProvider = FutureProvider.autoDispose
    .family<List<AdminAppointment>, AdminAppointmentKey>((ref, key) {
      final service = ref.watch(adminAppointmentServiceProvider);
      return loadAdmin(
        ref,
        key.owner,
        () => service.list(status: key.filter.status, date: key.filter.date),
      );
    }, retry: (_, _) => null);
final adminAppointmentProvider = FutureProvider.autoDispose
    .family<AdminAppointment, AdminResourceKey>((ref, key) {
      final service = ref.watch(adminAppointmentServiceProvider);
      return loadAdmin(ref, key.owner, () => service.get(key.id));
    }, retry: (_, _) => null);
final adminAppointmentMutationProvider =
    NotifierProvider.autoDispose<AdminAppointmentMutation, bool>(
      AdminAppointmentMutation.new,
    );

class AdminAppointmentMutation extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(adminOwnerProvider);
    return false;
  }

  Future<ApiResponse<void>> transition(String id, BookingStatus status) async {
    final owner = ref.read(adminOwnerProvider);
    if (state || !owner.authorized) {
      return const ApiResponse.failure('FORBIDDEN');
    }
    final appointment = ref
        .read(adminAppointmentProvider((owner: owner, id: id)))
        .asData
        ?.value;
    if (appointment == null ||
        !appointment.actionsAt(DateTime.now()).contains(status)) {
      return const ApiResponse.failure('VALIDATION_ERROR');
    }
    state = true;
    final result = await ApiErrorHandler.run(
      () => ref.read(adminAppointmentServiceProvider).transition(id, status),
    );
    if (!ref.mounted || owner != ref.read(adminOwnerProvider)) {
      return const ApiResponse.failure('SESSION_EXPIRED');
    }
    state = false;
    if (result.success || result.errorCode == 'CONFLICT') {
      ref.invalidate(adminAppointmentProvider((owner: owner, id: id)));
      ref.invalidate(adminAppointmentsProvider);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(appointmentsControllerProvider);
      ref.invalidate(appointmentDetailsProvider(id));
      ref.invalidate(bookingControllerProvider);
    }
    return result;
  }
}
