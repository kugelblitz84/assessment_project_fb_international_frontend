import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service_list_state.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';

final adminServiceFilterProvider = NotifierProvider.autoDispose
    .family<AdminServiceFilterController, AdminServiceFilter, bool>(
      AdminServiceFilterController.new,
    );

class AdminServiceFilterController extends Notifier<AdminServiceFilter> {
  AdminServiceFilterController(this.packages);
  final bool packages;
  @override
  AdminServiceFilter build() {
    ref.watch(adminOwnerProvider);
    return const AdminServiceFilter();
  }

  void search(String value) => state = state.copyWith(search: value);
  void category(String? value) => state = state.copyWith(category: value ?? '');
  void active(String? value) => state = state.copyWith(active: value ?? '');
}

final adminServiceListProvider = Provider.autoDispose
    .family<AsyncValue<AdminServiceListState>, bool>((ref, packages) {
      final filter = ref.watch(adminServiceFilterProvider(packages));
      return ref
          .watch(adminServicesProvider(ref.watch(adminOwnerProvider)))
          .whenData(
            (all) => AdminServiceListState(
              filter: filter,
              categories: {
                for (final item in all)
                  item.service.categoryId: item.service.categoryName,
              },
              items: all
                  .where(
                    (item) =>
                        item.service.isPackage == packages &&
                        (filter.category.isEmpty ||
                            item.service.categoryId == filter.category) &&
                        (filter.active.isEmpty ||
                            item.isActive == (filter.active == 'active')) &&
                        '${item.service.name} ${item.service.description}'
                            .toLowerCase()
                            .contains(filter.search.toLowerCase()),
                  )
                  .toList(),
            ),
          );
    });
