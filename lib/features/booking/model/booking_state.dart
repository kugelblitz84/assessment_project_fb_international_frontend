import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';

enum BookingStep { schedule, review }

class BookingState {
  const BookingState({
    required this.date,
    this.availability,
    this.slotId,
    this.step = BookingStep.schedule,
    this.loadingSlots = false,
    this.submitting = false,
    this.uncertain = false,
    this.errorCode,
    this.availabilityError,
    this.created,
  });
  final DateTime date;
  final AvailabilityModel? availability;
  final String? slotId;
  final BookingStep step;
  final bool loadingSlots;
  final bool submitting;
  final bool uncertain;
  final String? errorCode;
  final String? availabilityError;
  final AppointmentModel? created;
  TimeSlotModel? get selectedSlot {
    for (final slot in availability?.slots ?? const <TimeSlotModel>[]) {
      if (slot.id == slotId &&
          slot.available &&
          slot.startsAt.isAfter(DateTime.now())) {
        return slot;
      }
    }
    return null;
  }

  bool get canContinue =>
      selectedSlot != null &&
      !loadingSlots &&
      availabilityError == null &&
      !submitting &&
      !uncertain;
  BookingState copyWith({
    DateTime? date,
    AvailabilityModel? availability,
    bool clearAvailability = false,
    String? slotId,
    bool clearSlot = false,
    BookingStep? step,
    bool? loadingSlots,
    bool? submitting,
    bool? uncertain,
    String? errorCode,
    bool clearError = false,
    String? availabilityError,
    bool clearAvailabilityError = false,
    AppointmentModel? created,
  }) => BookingState(
    date: date ?? this.date,
    availability: clearAvailability ? null : availability ?? this.availability,
    slotId: clearSlot ? null : slotId ?? this.slotId,
    step: step ?? this.step,
    loadingSlots: loadingSlots ?? this.loadingSlots,
    submitting: submitting ?? this.submitting,
    uncertain: uncertain ?? this.uncertain,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
    availabilityError: clearAvailabilityError
        ? null
        : availabilityError ?? this.availabilityError,
    created: created ?? this.created,
  );
}
