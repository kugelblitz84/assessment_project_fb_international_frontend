import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/controller/admin_dashboard_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/service_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/service/admin_catalog_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_mutation_state.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/service_details_controller.dart';

final adminServicesProvider = FutureProvider.autoDispose
    .family<List<AdminService>, AdminOwner>((ref, owner) {
      final service = ref.watch(adminCatalogServiceProvider);
      return loadAdmin(ref, owner, service.list);
    }, retry: (_, _) => null);
final adminIndividualServicesProvider =
    Provider.autoDispose<AsyncValue<List<AdminService>>>(
      (ref) => ref
          .watch(adminServicesProvider(ref.watch(adminOwnerProvider)))
          .whenData(
            (items) => items
                .where((item) => !item.service.isPackage)
                .toList(growable: false),
          ),
    );
final adminServiceNamesProvider = Provider.autoDispose<Map<String, String>>(
  (ref) => {
    for (final item
        in ref
                .watch(adminServicesProvider(ref.watch(adminOwnerProvider)))
                .asData
                ?.value ??
            <AdminService>[])
      item.id: item.service.name,
  },
);
final adminServiceProvider = FutureProvider.autoDispose
    .family<AdminService, AdminResourceKey>((ref, key) {
      final service = ref.watch(adminCatalogServiceProvider);
      return loadAdmin(ref, key.owner, () => service.get(key.id));
    }, retry: (_, _) => null);
final adminServiceMutationProvider =
    NotifierProvider.autoDispose<AdminServiceMutation, AdminMutationState>(
      AdminServiceMutation.new,
    );

class AdminServiceMutation extends Notifier<AdminMutationState> {
  @override
  AdminMutationState build() {
    ref.watch(adminOwnerProvider);
    return const AdminMutationState();
  }

  Future<ApiResponse<void>> save(ServicePayload payload, {String? id}) async {
    final services =
        ref
            .read(adminServicesProvider(ref.read(adminOwnerProvider)))
            .asData
            ?.value ??
        const <AdminService>[];
    final validation = payload.validate(
      services
          .where((item) => !item.service.isPackage)
          .map((item) => item.id)
          .toSet(),
    );
    if (validation != null) {
      return const ApiResponse.failure('VALIDATION_ERROR');
    }
    return _run(
      () => ref.read(adminCatalogServiceProvider).save(payload, id: id),
    );
  }

  Future<ApiResponse<void>> setActive(String id, bool active) =>
      _run(() => ref.read(adminCatalogServiceProvider).setActive(id, active));
  Future<ApiResponse<void>> _run(Future<void> Function() action) async {
    final owner = ref.read(adminOwnerProvider);
    if (state.busy || !owner.authorized) {
      return const ApiResponse.failure('FORBIDDEN');
    }
    state = const AdminMutationState(busy: true);
    final result = await ApiErrorHandler.run(action);
    if (!ref.mounted || owner != ref.read(adminOwnerProvider)) {
      return const ApiResponse.failure('SESSION_EXPIRED');
    }
    state = AdminMutationState(errorCode: result.errorCode);
    if (result.success) {
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(catalogControllerProvider);
      ref.invalidate(serviceDetailsRequestProvider);
      ref.invalidate(adminServicesProvider);
      ref.invalidate(adminServiceProvider);
    }
    return result;
  }
}
