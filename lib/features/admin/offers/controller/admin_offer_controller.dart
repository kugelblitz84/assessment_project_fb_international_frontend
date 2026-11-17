import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/controller/admin_dashboard_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/admin_offer.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/offer_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/service/admin_offer_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/service_details_controller.dart';

final adminOffersProvider = FutureProvider.autoDispose
    .family<List<AdminOffer>, AdminOwner>((ref, owner) {
      final service = ref.watch(adminOfferServiceProvider);
      return loadAdmin(ref, owner, service.list);
    }, retry: (_, _) => null);
final adminOfferProvider = FutureProvider.autoDispose
    .family<AdminOffer, AdminResourceKey>((ref, key) {
      final service = ref.watch(adminOfferServiceProvider);
      return loadAdmin(ref, key.owner, () => service.get(key.id));
    }, retry: (_, _) => null);
final adminOfferMutationProvider =
    NotifierProvider.autoDispose<AdminOfferMutation, bool>(
      AdminOfferMutation.new,
    );

class AdminOfferMutation extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(adminOwnerProvider);
    return false;
  }

  Future<ApiResponse<void>> save(OfferPayload payload, {String? id}) async {
    final validation = payload.validationError;
    if (validation != null) {
      return const ApiResponse.failure('VALIDATION_ERROR');
    }
    return _run(
      () => ref.read(adminOfferServiceProvider).save(payload, id: id),
    );
  }

  Future<ApiResponse<void>> setActive(String id, bool active) =>
      _run(() => ref.read(adminOfferServiceProvider).setActive(id, active));
  Future<ApiResponse<void>> _run(Future<void> Function() action) async {
    final owner = ref.read(adminOwnerProvider);
    if (state || !owner.authorized) {
      return const ApiResponse.failure('FORBIDDEN');
    }
    state = true;
    final result = await ApiErrorHandler.run(action);
    if (!ref.mounted || owner != ref.read(adminOwnerProvider)) {
      return const ApiResponse.failure('SESSION_EXPIRED');
    }
    state = false;
    if (result.success) {
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(catalogControllerProvider);
      ref.invalidate(serviceDetailsRequestProvider);
      ref.invalidate(adminServicesProvider);
      ref.invalidate(adminServiceProvider);
      ref.invalidate(adminOffersProvider);
      ref.invalidate(adminOfferProvider);
    }
    return result;
  }
}
