import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/application/session_identity_provider.dart';
import '../../shared/controller/appointments_controller.dart';
import '../../shared/model/appointment_model.dart';

enum BookingsTab { upcoming, previous }

final myBookingsTabProvider =
    NotifierProvider<MyBookingsController, BookingsTab>(
      MyBookingsController.new,
    );

class MyBookingsController extends Notifier<BookingsTab> {
  @override
  BookingsTab build() {
    ref.watch(sessionIdentityProvider);
    return BookingsTab.upcoming;
  }

  void select(BookingsTab tab) => state = tab;
}

final visibleAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final tab = ref.watch(myBookingsTabProvider);
  final owner = ref.watch(sessionIdentityProvider).userId;
  final data = ref.watch(
    appointmentsControllerProvider.select(
      (state) => (
        ownerId: state.asData?.value.ownerId,
        items: state.asData?.value.items ?? const <AppointmentModel>[],
      ),
    ),
  );
  if (owner == null || data.ownerId != owner) return const [];
  final items =
      data.items
          .where(
            (appointment) => tab == BookingsTab.upcoming
                ? appointment.upcoming
                : !appointment.upcoming,
          )
          .toList()
        ..sort(
          (a, b) => tab == BookingsTab.upcoming
              ? a.slot.startsAt.compareTo(b.slot.startsAt)
              : b.slot.startsAt.compareTo(a.slot.startsAt),
        );
  return List.unmodifiable(items);
});
