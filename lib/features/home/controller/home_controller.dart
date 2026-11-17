import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/controller/catalog_controller.dart';
import '../../shared/model/service_model.dart';
import '../model/home_state.dart';

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
final filteredServicesProvider = Provider<List<ServiceModel>>((ref) {
  final filter = ref.watch(homeControllerProvider);
  final services =
      ref.watch(catalogControllerProvider).asData?.value.services ??
      const <ServiceModel>[];
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

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();
  void search(String query) => state = state.copyWith(query: query);
  void category(String? id) {
    final services =
        ref.read(catalogControllerProvider).asData?.value.services ??
        const <ServiceModel>[];
    if (id != null && !services.any((s) => s.categoryId == id)) return;
    state = state.copyWith(categoryId: id, clearCategory: id == null);
  }

  void clear() => state = const HomeState();

  Future<void> browse(String? categoryId) async {
    await ref.read(catalogControllerProvider.future);
    if (!ref.mounted) return;
    clear();
    category(categoryId);
  }
}
