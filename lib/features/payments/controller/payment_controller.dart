import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_identity_provider.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../shared/model/appointment_model.dart';
import '../../shared/controller/appointments_controller.dart';
import '../../shared/service/appointment_service.dart';
import '../model/payment_models.dart';
import '../service/payment_service.dart';

typedef PaymentKey = ({SessionIdentity identity, String appointmentId});

class PaymentState {
  const PaymentState({
    required this.appointment,
    required this.attempts,
    this.busy = false,
    this.uncertain = false,
    this.error,
  });
  final AppointmentModel appointment;
  final List<PaymentAttempt> attempts;
  final bool busy, uncertain;
  final String? error;
  PaymentState copy({bool? busy, bool? uncertain, String? error}) =>
      PaymentState(
        appointment: appointment,
        attempts: attempts,
        busy: busy ?? this.busy,
        uncertain: uncertain ?? this.uncertain,
        error: error,
      );
  bool get hasUnresolved =>
      attempts.any((p) => p.status.unresolved || p.applied);
}

final paymentControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PaymentController, PaymentState, PaymentKey>(
      PaymentController.new,
      retry: (_, _) => null,
    );

class PaymentController extends AsyncNotifier<PaymentState> {
  PaymentController(this.key);
  final PaymentKey key;
  bool get owned =>
      ref.mounted &&
      key.identity == ref.read(sessionIdentityProvider) &&
      ref.read(currentUserProvider) != null;
  @override
  Future<PaymentState> build() async {
    ref.watch(sessionIdentityProvider);
    if (!owned) throw const FormatException('Session changed.');
    return _load();
  }

  Future<PaymentState> _load() async {
    final user = ref.read(currentUserProvider)!;
    final attempts = await ref
        .read(paymentServiceProvider)
        .history(key.appointmentId);
    if (!owned) throw const FormatException('Session changed.');
    final appointment = await ref
        .read(appointmentServiceProvider)
        .getBooking(user.id, key.appointmentId);
    if (!owned) throw const FormatException('Session changed.');
    return PaymentState(appointment: appointment, attempts: attempts);
  }

  void _sync() {
    ref.invalidate(appointmentsControllerProvider);
    ref.invalidate(appointmentDetailsProvider(key.appointmentId));
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (!owned || current == null || current.busy) return;
    state = AsyncData(current.copy(busy: true));
    final result = await ApiErrorHandler.run(() async {
      final attempts = await ref
          .read(paymentServiceProvider)
          .history(key.appointmentId);
      for (final attempt in attempts.where((p) => p.status.unresolved)) {
        if (!owned) return;
        await ref
            .read(reconciliationGateProvider)
            .run(
              attempt.paymentId,
              () =>
                  ref.read(paymentServiceProvider).reconcile(attempt.paymentId),
            );
      }
    });
    if (!owned) return;
    final fresh = await ApiErrorHandler.run(_load);
    if (!owned) return;
    state = AsyncData(
      (fresh.data ?? current).copy(
        error: result.errorCode ?? fresh.errorCode,
        uncertain:
            current.uncertain &&
            (fresh.data == null || fresh.data!.attempts.isEmpty),
      ),
    );
    _sync();
  }

  Future<PaymentAttempt?> initiate(CheckoutContact contact) async {
    final current = state.asData?.value;
    if (!owned || current == null || current.busy || current.uncertain) {
      return null;
    }
    state = AsyncData(current.copy(busy: true));
    // Fetch authoritative eligibility/history before every attempt, including retries.
    final preflight = await ApiErrorHandler.run(() async {
      final config = await ref.read(paymentServiceProvider).config();
      if (!owned) throw const FormatException('Session changed.');
      if (!config.onlinePaymentEnabled) return null;
      return _load();
    });
    if (!owned) return null;
    final fresh = preflight.data;
    if (fresh == null ||
        fresh.hasUnresolved ||
        !fresh.appointment.canPayOnline) {
      state = AsyncData(
        (fresh ?? current).copy(
          error: preflight.errorCode ?? 'PAYMENT_NOT_ELIGIBLE',
        ),
      );
      _sync();
      return null;
    }
    final result = await ApiErrorHandler.run(
      () =>
          ref.read(paymentServiceProvider).initiate(key.appointmentId, contact),
    );
    if (!owned) return null;
    final uncertain =
        !result.success &&
        !const {
          'VALIDATION_ERROR',
          'PAYMENTS_DISABLED',
          'PAYMENT_NOT_ELIGIBLE',
          'PAYMENT_CONTACT_UNSUPPORTED',
          'APPOINTMENT_ALREADY_PAID',
          'PAYMENT_RATE_LIMITED',
        }.contains(result.errorCode);
    final updated = await ApiErrorHandler.run(_load);
    if (!owned) return null;
    state = AsyncData(
      (updated.data ?? fresh).copy(
        error: result.errorCode ?? updated.errorCode,
        uncertain: uncertain,
      ),
    );
    _sync();
    if (uncertain) await refresh();
    return result.data;
  }
}
