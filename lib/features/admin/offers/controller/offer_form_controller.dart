import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/controller/admin_offer_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/admin_offer.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/offer_form_state.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/offer_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/offer_validation.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_time.dart';

typedef OfferFormKey = ({
  Object owner,
  AdminOffer? item,
  String firstServiceId,
});
final offerFormProvider = NotifierProvider.autoDispose
    .family<OfferFormController, OfferFormState, OfferFormKey>(
      OfferFormController.new,
    );

class OfferFormController extends Notifier<OfferFormState> {
  OfferFormController(this.key);
  final OfferFormKey key;
  @override
  OfferFormState build() {
    ref.watch(adminOwnerProvider);
    return OfferFormState(
      serviceId: key.item?.serviceId ?? key.firstServiceId,
      type: key.item?.discountType ?? 'PERCENTAGE',
      active: key.item?.isActive ?? true,
    );
  }

  void selectService(String? id) {
    if (id != null) state = state.copyWith(serviceId: id);
  }

  void selectType(String? value) {
    if (value != null) state = state.copyWith(type: value);
  }

  void setActive(bool value) => state = state.copyWith(active: value);

  Future<ApiResponse<void>?> save({
    required String title,
    required String description,
    required String value,
    required String start,
    required String end,
  }) async {
    if (!ref.mounted) return null;
    final startsAt = WorkshopTime.parse(start),
        endsAt = WorkshopTime.parse(end);
    final error = OfferValidation.offer(state.type, value, startsAt, endsAt);
    state = state.copyWith(error: error);
    if (error != null) return null;
    return ref
        .read(adminOfferMutationProvider.notifier)
        .save(
          OfferPayload(
            serviceId: state.serviceId,
            title: title,
            description: description,
            discountType: state.type,
            discountValue: value,
            startsAt: startsAt!,
            endsAt: endsAt!,
            isActive: state.active,
          ),
          id: key.item?.id,
        );
  }
}
