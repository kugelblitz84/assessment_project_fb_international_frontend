import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/service_catalog_service.dart';

/// Complete cached catalog entries render immediately. A direct link missing
/// from that snapshot uses the documented detail endpoint, with no second list.
final serviceDetailsProvider = Provider.autoDispose
    .family<AsyncValue<ServiceModel?>, String>((ref, id) {
      final catalog = ref.watch(catalogControllerProvider);
      final snapshot = catalog.asData?.value;
      if (snapshot != null) {
        for (final service in snapshot.services) {
          if (service.id == id) return AsyncData(service);
        }
        if (snapshot.errorCode == null) {
          return ref.watch(serviceDetailsRequestProvider(id));
        }
      }
      return catalog.whenData((_) => null);
    });

final serviceDetailsRequestProvider = FutureProvider.autoDispose
    .family<ServiceModel?, String>((ref, id) async {
      final service = ref.watch(serviceCatalogProvider);
      final result = await ApiErrorHandler.run(() => service.getService(id));
      if (!result.success) throw ApiFailure(result.errorCode!);
      return result.data;
    }, retry: (_, _) => null);
