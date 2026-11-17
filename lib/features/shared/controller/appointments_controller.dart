import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/session/application/session_identity_provider.dart';
import '../../../core/session/domain/auth_state.dart';
import '../model/appointments_state.dart';
import '../service/appointment_service.dart';

final appointmentsControllerProvider =
    AsyncNotifierProvider<AppointmentsController, AppointmentsState>(
      AppointmentsController.new,
    );
final appointmentDetailsProvider = AsyncNotifierProvider.autoDispose
    .family<AppointmentDetailsController, AppointmentDetailsState, String>(
      AppointmentDetailsController.new,
    );

class AppointmentsController extends AsyncNotifier<AppointmentsState> {
  int _generation = 0;
  @override
  Future<AppointmentsState> build() async {
    _generation++;
    ref.watch(sessionIdentityProvider);
    final session = ref.read(sessionProvider).asData?.value;
    final service = ref.watch(appointmentServiceProvider);
    if (session is! Authenticated) {
      return const AppointmentsState(ownerId: null);
    }
    final result = await ApiErrorHandler.run(
      () => service.getBookings(session.user.id),
    );
    return AppointmentsState(
      ownerId: session.user.id,
      items: result.data ?? const [],
      errorCode: result.errorCode,
    );
  }

  Future<void> refresh() async {
    final generation = _generation;
    final current = state.asData?.value;
    final identity = ref.read(sessionIdentityProvider);
    final session = ref.read(sessionProvider).asData?.value;
    if (current == null ||
        current.refreshing ||
        session is! Authenticated ||
        current.ownerId != session.user.id) {
      return;
    }
    state = AsyncData(current.copyWith(refreshing: true, clearError: true));
    final result = await ApiErrorHandler.run(
      () => ref.read(appointmentServiceProvider).getBookings(session.user.id),
    );
    if (!ref.mounted ||
        generation != _generation ||
        identity != ref.read(sessionIdentityProvider)) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        items: result.data,
        refreshing: false,
        errorCode: result.errorCode,
        clearError: result.success,
      ),
    );
  }
}

class AppointmentDetailsController
    extends AsyncNotifier<AppointmentDetailsState> {
  AppointmentDetailsController(this.bookingId);
  final String bookingId;
  @override
  Future<AppointmentDetailsState> build() async {
    ref.watch(sessionIdentityProvider);
    final session = ref.read(sessionProvider).asData?.value;
    final service = ref.watch(appointmentServiceProvider);
    if (session is! Authenticated) {
      return const AppointmentDetailsState(ownerId: null);
    }
    final result = await ApiErrorHandler.run(
      () => service.getBooking(session.user.id, bookingId),
    );
    return AppointmentDetailsState(
      ownerId: session.user.id,
      appointment: result.data,
      errorCode: result.errorCode,
    );
  }

  Future<bool> cancel() async {
    final current = state.asData?.value;
    final identity = ref.read(sessionIdentityProvider);
    final session = ref.read(sessionProvider).asData?.value;
    if (current == null ||
        current.busy ||
        current.appointment?.canCancel != true ||
        session is! Authenticated ||
        current.ownerId != session.user.id) {
      return false;
    }
    state = AsyncData(current.copyWith(busy: true, clearError: true));
    final result = await ApiErrorHandler.run(
      () => ref
          .read(appointmentServiceProvider)
          .cancel(session.user.id, bookingId),
    );
    if (!ref.mounted || identity != ref.read(sessionIdentityProvider)) {
      return false;
    }
    state = AsyncData(
      current.copyWith(
        appointment: result.data,
        busy: false,
        errorCode: result.errorCode,
        clearError: result.success,
      ),
    );
    if (result.success) ref.invalidate(appointmentsControllerProvider);
    return result.success;
  }
}
