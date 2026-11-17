import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../routes/app_routes.dart';
import '../../controller/booking_controller.dart';
import '../../model/booking_state.dart';

class BookingActionButton extends ConsumerWidget {
  const BookingActionButton({super.key, required this.serviceId});
  final String serviceId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = bookingControllerProvider(serviceId);
    final draft = ref.watch(provider).asData?.value;
    final controller = ref.watch(provider.notifier);
    if (draft == null) return const SizedBox.shrink();
    if (draft.uncertain) {
      return AppButton(
        label: 'Check my bookings',
        onPressed: () => context.goNamed(AppRoutes.myBookings),
      );
    }
    return AppButton(
      label: draft.submitting
          ? 'Submitting booking…'
          : draft.step == BookingStep.schedule
          ? 'Continue to review'
          : 'Confirm booking',
      loading: draft.submitting,
      onPressed: draft.canContinue
          ? (draft.step == BookingStep.schedule
                ? controller.review
                : controller.submit)
          : null,
      icon: draft.step == BookingStep.schedule
          ? Icons.arrow_forward
          : Icons.check,
    );
  }
}
