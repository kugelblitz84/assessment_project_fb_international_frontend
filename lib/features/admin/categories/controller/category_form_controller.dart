import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/controller/admin_category_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/admin_category.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/category_form_state.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/category_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/controller/admin_image_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';

typedef CategoryFormKey = ({AdminImageKey image, AdminCategory? item});
final categoryFormProvider = NotifierProvider.autoDispose
    .family<CategoryFormController, CategoryFormState, CategoryFormKey>(
      CategoryFormController.new,
    );

class CategoryFormController extends Notifier<CategoryFormState> {
  CategoryFormController(this.key);
  final CategoryFormKey key;
  @override
  CategoryFormState build() {
    ref.watch(adminOwnerProvider);
    return CategoryFormState(active: key.item?.isActive ?? true);
  }

  void setActive(bool value) => state = CategoryFormState(active: value);
  bool get requiresStatusConfirmation =>
      key.item != null && key.item!.isActive != state.active;

  Future<ApiResponse<void>?> save({
    required String name,
    required String slug,
    required String description,
    required String sortOrder,
  }) async {
    if (!ref.mounted) return null;
    final image = ref.read(adminImageProvider(key.image));
    if (image.busy) return null;
    final error = AdminValidation.integer(sortOrder);
    if (error != null) {
      state = CategoryFormState(active: state.active, error: error);
      return null;
    }
    state = CategoryFormState(active: state.active);
    return ref
        .read(adminCategoryMutationProvider.notifier)
        .save(
          CategoryPayload(
            name: name,
            slug: slug,
            description: description,
            sortOrder: int.parse(sortOrder),
            isActive: state.active,
            imageUrl: image.url,
          ),
          id: key.item?.id,
        );
  }
}
