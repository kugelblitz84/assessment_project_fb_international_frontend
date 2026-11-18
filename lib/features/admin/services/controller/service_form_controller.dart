import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/controller/admin_image_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/service_form_state.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/service_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';

typedef ServiceFormKey = ({
  AdminImageKey image,
  AdminService? item,
  bool package,
  String firstCategoryId,
  List<AdminService> individuals,
});
final serviceFormProvider = NotifierProvider.autoDispose
    .family<ServiceFormController, ServiceFormState, ServiceFormKey>(
      ServiceFormController.new,
    );

class ServiceFormController extends Notifier<ServiceFormState> {
  ServiceFormController(this.key);
  final ServiceFormKey key;
  int _nextInclusion = 0;
  @override
  ServiceFormState build() {
    ref.watch(adminOwnerProvider);
    final values = key.item?.service.inclusions ?? <String>[];
    _nextInclusion = values.length;
    return ServiceFormState(
      categoryId: key.item?.service.categoryId ?? key.firstCategoryId,
      active: key.item?.isActive ?? true,
      featured: key.item?.isFeatured ?? false,
      inclusions: {for (var i = 0; i < values.length; i++) i: values[i]},
      quantities: {
        for (final item in key.item?.items ?? <PackageItem>[])
          item.serviceId: '${item.quantity}',
      },
    );
  }

  void selectCategory(String? id) {
    if (id != null) state = state.copyWith(categoryId: id);
  }

  void setActive(bool value) => state = state.copyWith(active: value);
  void setFeatured(bool value) => state = state.copyWith(featured: value);
  void addInclusion() {
    if (state.inclusions.length >= 100) return;
    state = state.copyWith(
      inclusions: {...state.inclusions, _nextInclusion++: ''},
    );
  }

  void updateInclusion(int id, String value) {
    if (state.inclusions.containsKey(id)) {
      state = state.copyWith(inclusions: {...state.inclusions, id: value});
    }
  }

  void removeInclusion(int id) =>
      state = state.copyWith(inclusions: {...state.inclusions}..remove(id));
  List<AdminService> get remaining => key.individuals
      .where((item) => !state.quantities.containsKey(item.id))
      .toList(growable: false);
  void addItem(String? id) {
    if (id == null || !remaining.any((item) => item.id == id)) return;
    state = state.copyWith(quantities: {...state.quantities, id: '1'});
  }

  void updateQuantity(String id, String value) {
    if (state.quantities.containsKey(id)) {
      state = state.copyWith(quantities: {...state.quantities, id: value});
    }
  }

  Map<String, String> get componentNames => {
    for (final item in key.individuals) item.id: item.service.name,
  };

  void removeItem(String id) =>
      state = state.copyWith(quantities: {...state.quantities}..remove(id));
  bool get requiresStatusConfirmation =>
      key.item != null && key.item!.isActive != state.active;
  Future<ApiResponse<void>?> save({
    required String name,
    required String slug,
    required String description,
    required String price,
    required String duration,
    required String sortOrder,
  }) async {
    if (!ref.mounted) return null;
    final image = ref.read(adminImageProvider(key.image));
    if (image.busy) return null;
    final numbersError =
        AdminValidation.integer(duration, min: 1, max: 1440) ??
        AdminValidation.integer(sortOrder);
    if (numbersError != null) {
      state = state.copyWith(error: numbersError);
      return null;
    }
    final payload = ServicePayload(
      name: name,
      slug: slug,
      description: description,
      categoryId: state.categoryId,
      type: key.package ? 'PACKAGE' : 'INDIVIDUAL',
      price: price,
      durationMinutes: int.parse(duration),
      sortOrder: int.parse(sortOrder),
      isActive: state.active,
      isFeatured: state.featured,
      imageUrl: image.url,
      inclusions: state.inclusions.values.map((value) => value.trim()).toList(),
      packageItems: [
        for (final entry in state.quantities.entries)
          PackageItem(
            serviceId: entry.key,
            quantity: int.tryParse(entry.value) ?? 0,
          ),
      ],
    );
    final error = payload.validate(
      key.individuals.map((item) => item.id).toSet(),
    );
    state = state.copyWith(error: error);
    if (error != null) return null;
    return ref
        .read(adminServiceMutationProvider.notifier)
        .save(payload, id: key.item?.id);
  }
}
