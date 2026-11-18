import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/features/admin/payments/model/payment_filter_state.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';

final paymentFilterProvider =
    NotifierProvider.autoDispose<PaymentFilterController, PaymentFilterState>(
      PaymentFilterController.new,
    );

class PaymentFilterController extends Notifier<PaymentFilterState> {
  @override
  PaymentFilterState build() {
    ref.watch(adminOwnerProvider);
    return const PaymentFilterState();
  }

  void select(String? value) => state = PaymentFilterState(
    status: PaymentStatus.values.any((s) => s.apiValue == value) ? value! : '',
  );
}
