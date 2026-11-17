import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/home/model/home_state.dart';

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
final filteredServicesProvider = Provider<List<ServiceModel>>((ref) {
  final filter = ref.watch(homeControllerProvider);
  final services = ref.watch(catalogServicesProvider);
  final query = filter.query.trim().toLowerCase();
  return services
      .where(
        (s) =>
            (filter.categoryId == null || s.categoryId == filter.categoryId) &&
            (query.isEmpty ||
                '${s.name} ${s.description} ${s.categoryName}'
                    .toLowerCase()
                    .contains(query)),
      )
      .toList(growable: false);
});

final serviceCategoriesProvider = Provider<Map<String, String>>(
  (ref) => Map.unmodifiable({
    for (final service in ref.watch(catalogServicesProvider))
      service.categoryId: service.categoryName,
  }),
);

class HomeController extends Notifier<HomeState> {
  int _filterRequest = 0;
  @override
  HomeState build() => const HomeState();
  void search(String query) {
    _filterRequest++;
    state = state.copyWith(query: query);
  }

  void category(String? id) {
    _filterRequest++;
    if (id != null && !ref.read(serviceCategoriesProvider).containsKey(id)) {
      return;
    }
    state = state.copyWith(categoryId: id, clearCategory: id == null);
  }

  void clear() {
    _filterRequest++;
    state = const HomeState();
  }

  Future<void> browse(String? categoryId) async {
    final request = ++_filterRequest;
    await ref.read(catalogControllerProvider.future);
    if (!ref.mounted || request != _filterRequest) return;
    final categories = ref.read(serviceCategoriesProvider);
    state = HomeState(
      categoryId: categories.containsKey(categoryId) ? categoryId : null,
    );
  }
}
