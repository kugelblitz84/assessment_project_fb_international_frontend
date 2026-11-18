import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/controller/admin_appointment_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/payments/service/admin_payment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/controller/appointments_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/controller/reconciliation_gate.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';

typedef AdminPaymentKey = ({AdminOwner owner, String? status});
final adminPaymentsProvider = FutureProvider.autoDispose
    .family<List<AdminPayment>, AdminPaymentKey>((ref, key) {
      final service = ref.watch(adminPaymentServiceProvider);
      return loadAdmin(ref, key.owner, () => service.list(status: key.status));
    }, retry: (_, _) => null);
final adminPaymentProvider = FutureProvider.autoDispose
    .family<AdminPayment, AdminResourceKey>((ref, key) {
      final service = ref.watch(adminPaymentServiceProvider);
      return loadAdmin(ref, key.owner, () => service.get(key.id));
    }, retry: (_, _) => null);
final adminPaymentMutationProvider =
    NotifierProvider.autoDispose<AdminPaymentMutation, bool>(
      AdminPaymentMutation.new,
    );

class AdminPaymentMutation extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(sessionIdentityProvider);
    ref.watch(adminAccessProvider);
    return false;
  }

  Future<ApiResponse<void>> reconcile(String id) async {
    if (state || !ref.read(adminAccessProvider)) {
      return const ApiResponse.failure('FORBIDDEN');
    }
    final owner = ref.read(adminOwnerProvider);
    state = true;
    var throttled = false;
    final result = await ApiErrorHandler.run<void>(() async {
      final updated = await ref
          .read(reconciliationGateProvider)
          .run(id, () => ref.read(adminPaymentServiceProvider).reconcile(id));
      throttled = updated == null;
    });
    if (!ref.mounted || owner != ref.read(adminOwnerProvider)) {
      return const ApiResponse.failure('UNAUTHORIZED');
    }
    state = false;
    ref.invalidate(adminPaymentProvider((owner: owner, id: id)));
    ref.invalidate(adminPaymentsProvider);
    ref.invalidate(adminAppointmentProvider);
    ref.invalidate(adminAppointmentsProvider);
    ref.invalidate(appointmentsControllerProvider);
    ref.invalidate(appointmentDetailsProvider);
    return throttled
        ? const ApiResponse.failure('PAYMENT_RECONCILE_THROTTLED')
        : result;
  }
}
