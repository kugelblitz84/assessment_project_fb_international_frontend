import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/session/domain/auth_state.dart';
import '../../shared/controller/appointments_controller.dart';
import '../../shared/model/create_booking_payload.dart';
import '../../shared/service/appointment_service.dart';
import '../model/booking_state.dart';
import '../service/booking_service.dart';

final bookingControllerProvider = AsyncNotifierProvider.autoDispose
    .family<BookingController, BookingState, String>(BookingController.new);

class BookingController extends AsyncNotifier<BookingState> {
  BookingController(this.serviceId);
  final String serviceId;
  int _request = 0;

  @override
  Future<BookingState> build() async {
    _request++;
    final session = ref.watch(sessionProvider).asData?.value;
    final service = ref.watch(bookingServiceProvider);
    final date = service.today;
    if (session is! Authenticated) {
      return BookingState(date: date, availabilityError: 'UNAUTHORIZED');
    }
    final result = await ApiErrorHandler.run(
      () => service.getAvailability(serviceId, date),
    );
    return BookingState(
      date: date,
      availability: result.data,
      availabilityError: result.errorCode,
    );
  }

  Future<void> selectDate(DateTime date) async {
    final current = state.asData?.value;
    if (current == null ||
        current.submitting ||
        current.uncertain ||
        current.created != null) {
      return;
    }
    final request = ++_request;
    state = AsyncData(
      current.copyWith(
        date: date,
        clearSlot: true,
        clearAvailability: true,
        loadingSlots: true,
        step: 0,
        clearAvailabilityError: true,
      ),
    );
    final result = await ApiErrorHandler.run(
      () => ref.read(bookingServiceProvider).getAvailability(serviceId, date),
    );
    if (!ref.mounted || request != _request) return;
    state = AsyncData(
      state.requireValue.copyWith(
        availability: result.data,
        loadingSlots: false,
        availabilityError: result.errorCode,
        clearAvailabilityError: result.success,
      ),
    );
  }

  void selectSlot(String id) {
    final current = state.asData?.value;
    if (current == null ||
        current.loadingSlots ||
        current.submitting ||
        current.uncertain) {
      return;
    }
    if (current.availability?.slots.any((s) => s.id == id && s.available) !=
        true) {
      return;
    }
    state = AsyncData(current.copyWith(slotId: id, clearError: true));
  }

  void review() {
    final current = state.asData?.value;
    if (current?.canContinue == true) {
      state = AsyncData(current!.copyWith(step: 1, clearError: true));
    }
  }

  void edit() {
    final current = state.asData?.value;
    if (current != null && !current.submitting && !current.uncertain) {
      state = AsyncData(current.copyWith(step: 0));
    }
  }

  Future<void> submit() async {
    final current = state.asData?.value;
    final session = ref.read(sessionProvider).asData?.value;
    if (current == null ||
        !current.canContinue ||
        current.step != 1 ||
        current.created != null ||
        session is! Authenticated) {
      return;
    }
    final request = ++_request;
    state = AsyncData(current.copyWith(submitting: true, clearError: true));
    final payload = CreateBookingPayload(
      serviceId: serviceId,
      slotId: current.slotId!,
    );
    final result = await ApiErrorHandler.run(
      () =>
          ref.read(appointmentServiceProvider).create(session.user.id, payload),
    );
    if (!ref.mounted ||
        request != _request ||
        !identical(session, ref.read(sessionProvider).asData?.value)) {
      return;
    }
    if (result.success) {
      state = AsyncData(
        current.copyWith(
          submitting: false,
          created: result.data,
          clearError: true,
        ),
      );
      ref.invalidate(appointmentsControllerProvider);
      return;
    }
    final uncertain =
        result.errorCode == 'TIMEOUT' ||
        result.errorCode == 'NETWORK_ERROR' ||
        result.errorCode == 'SERVER_ERROR';
    state = AsyncData(
      current.copyWith(
        submitting: false,
        errorCode: result.errorCode,
        uncertain: uncertain,
      ),
    );
    if (result.errorCode == 'CONFLICT') {
      // Generic conflicts do not claim a particular backend domain error.
      await selectDate(current.date);
    }
  }
}
