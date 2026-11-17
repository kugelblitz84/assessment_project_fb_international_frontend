import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/admin_category.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/category_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/service/admin_category_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/controller/admin_dashboard_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/service_details_controller.dart';

final adminCategoriesProvider = FutureProvider.autoDispose
    .family<List<AdminCategory>, AdminOwner>((ref, owner) {
      final service = ref.watch(adminCategoryServiceProvider);
      return loadAdmin(ref, owner, service.list);
    }, retry: (_, _) => null);
final adminCategoryProvider = FutureProvider.autoDispose
    .family<AdminCategory, AdminResourceKey>((ref, key) {
      final service = ref.watch(adminCategoryServiceProvider);
      return loadAdmin(ref, key.owner, () => service.get(key.id));
    }, retry: (_, _) => null);
final adminCategoryMutationProvider =
    NotifierProvider.autoDispose<AdminCategoryMutation, bool>(
      AdminCategoryMutation.new,
    );

class AdminCategoryMutation extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(adminOwnerProvider);
    return false;
  }

  Future<ApiResponse<void>> save(CategoryPayload payload, {String? id}) async {
    final validation = payload.validationError;
    if (validation != null) {
      return const ApiResponse.failure('VALIDATION_ERROR');
    }
    return _run(
      () => ref.read(adminCategoryServiceProvider).save(payload, id: id),
    );
  }

  Future<ApiResponse<void>> setActive(String id, bool active) =>
      _run(() => ref.read(adminCategoryServiceProvider).setActive(id, active));
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
      ref.invalidate(adminCategoriesProvider);
      ref.invalidate(adminCategoryProvider);
    }
    return result;
  }
}
