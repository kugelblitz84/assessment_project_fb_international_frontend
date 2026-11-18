import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/controller/appointments_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/create_booking_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/service/appointment_service.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_date_selection.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/service/booking_service.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/controller/platform_config_provider.dart';

final bookingControllerProvider = AsyncNotifierProvider.autoDispose
    .family<BookingController, BookingState, String>(
      BookingController.new,
      retry: (_, _) => null,
    );

class BookingController extends AsyncNotifier<BookingState> {
  BookingController(this.serviceId);
  final String serviceId;
  int _request = 0;
  ({BookingDateSelection selection, SessionIdentity identity, int request})?
  _dateSelection;
  bool get configurationFresh =>
      ref.read(platformConfigProvider).asData?.value.fresh == true;
  DateTime get firstBookableDate => ref.read(bookingServiceProvider).today;
  DateTime get lastBookableDate =>
      ref.read(platformConfigProvider).requireValue.lastDate(firstBookableDate);

  @override
  Future<BookingState> build() async {
    _request++;
    _dateSelection = null;
    ref.watch(sessionIdentityProvider);
    final session = ref.read(sessionProvider).asData?.value;
    final service = ref.watch(bookingServiceProvider);
    final date = service.today;
    if (session is! Authenticated) {
      return BookingState(date: date, availabilityError: 'UNAUTHORIZED');
    }
    final config = await ref.watch(platformConfigProvider.future);
    if (!config.fresh) {
      ref.invalidate(platformConfigProvider);
      throw const FormatException(
        'Workshop configuration expired. Retry loading booking settings.',
      );
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

  BookingDateSelection? prepareDateSelection() {
    if (!ref.mounted) return null;
    final current = state.asData?.value;
    if (current == null ||
        current.submitting ||
        current.uncertain ||
        current.created != null) {
      return null;
    }
    if (!configurationFresh) {
      ref.invalidate(platformConfigProvider);
      return null;
    }
    final first = firstBookableDate;
    final last = lastBookableDate;
    final selection = BookingDateSelection(
      firstDate: first,
      lastDate: last,
      initialDate: current.date.isBefore(first)
          ? first
          : current.date.isAfter(last)
          ? last
          : current.date,
    );
    _dateSelection = (
      selection: selection,
      identity: ref.read(sessionIdentityProvider),
      request: _request,
    );
    return selection;
  }

  Future<void> selectDate(
    DateTime date, {
    BookingDateSelection? selection,
  }) async {
    if (!ref.mounted) return;
    if (selection != null) {
      final pending = _dateSelection;
      if (pending == null ||
          !identical(selection, pending.selection) ||
          pending.identity != ref.read(sessionIdentityProvider) ||
          pending.request != _request) {
        return;
      }
      _dateSelection = null;
    }
    await _loadAvailability(
      date,
      preserveSelection: state.asData?.value.date == date,
    );
  }

  Future<void> _loadAvailability(
    DateTime date, {
    required bool preserveSelection,
  }) async {
    final current = state.asData?.value;
    if (current == null ||
        current.submitting ||
        current.uncertain ||
        current.created != null) {
      return;
    }
    if (!configurationFresh) {
      ref.invalidate(platformConfigProvider);
      return;
    }
    if (date.isBefore(firstBookableDate) || date.isAfter(lastBookableDate)) {
      return;
    }
    if (current.loadingSlots && current.date == date) return;
    final identity = ref.read(sessionIdentityProvider);
    final request = ++_request;
    state = AsyncData(
      current.copyWith(
        date: date,
        clearSlot: !preserveSelection,
        clearAvailability: !preserveSelection,
        loadingSlots: true,
        step: preserveSelection ? current.step : BookingStep.schedule,
        clearAvailabilityError: true,
      ),
    );
    final result = await ApiErrorHandler.run(
      () => ref.read(bookingServiceProvider).getAvailability(serviceId, date),
    );
    if (!ref.mounted ||
        request != _request ||
        identity != ref.read(sessionIdentityProvider)) {
      return;
    }
    final validSelection =
        result.data?.slots.any(
          (slot) => slot.id == current.slotId && slot.available,
        ) ==
        true;
    state = AsyncData(
      state.requireValue.copyWith(
        availability: result.data,
        clearSlot: result.success && !validSelection,
        step: result.success && !validSelection ? BookingStep.schedule : null,
        loadingSlots: false,
        availabilityError: result.errorCode,
        clearAvailabilityError: result.success,
      ),
    );
  }

  Future<void> refreshAvailability() async {
    if (!configurationFresh) {
      ref.invalidate(platformConfigProvider);
      return;
    }
    final current = state.asData?.value;
    if (current == null || current.loadingSlots) return;
    final today = ref.read(bookingServiceProvider).today;
    await _loadAvailability(
      current.date.isBefore(today) ? today : current.date,
      preserveSelection: !current.date.isBefore(today),
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
      state = AsyncData(
        current!.copyWith(step: BookingStep.review, clearError: true),
      );
    }
  }

  void edit() {
    final current = state.asData?.value;
    if (current != null && !current.submitting && !current.uncertain) {
      state = AsyncData(current.copyWith(step: BookingStep.schedule));
    }
  }

  Future<void> submit() async {
    if (!configurationFresh) {
      ref.invalidate(platformConfigProvider);
      return;
    }
    final current = state.asData?.value;
    final identity = ref.read(sessionIdentityProvider);
    final session = ref.read(sessionProvider).asData?.value;
    if (current == null ||
        !current.canContinue ||
        current.step != BookingStep.review ||
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
        identity != ref.read(sessionIdentityProvider)) {
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
        const {
          'TIMEOUT',
          'CONNECTION_TIMEOUT',
          'SEND_TIMEOUT',
          'RECEIVE_TIMEOUT',
          'CANCELLED',
          'BACKEND_UNAVAILABLE',
        }.contains(result.errorCode) ||
        result.errorCode == 'NETWORK_ERROR' ||
        result.errorCode == 'SERVER_ERROR' ||
        result.errorCode == 'INVALID_RESPONSE' ||
        result.errorCode == 'UNEXPECTED_ERROR';
    state = AsyncData(
      current.copyWith(
        submitting: false,
        errorCode: result.errorCode,
        uncertain: uncertain,
      ),
    );
    if (uncertain) ref.invalidate(appointmentsControllerProvider);
    if (result.errorCode == 'CONFLICT') {
      // Generic conflicts do not claim a particular backend domain error.
      await _loadAvailability(current.date, preserveSelection: false);
    }
  }
}
