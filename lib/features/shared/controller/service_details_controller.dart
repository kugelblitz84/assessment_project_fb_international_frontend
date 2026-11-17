import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_controller.dart';
import '../model/service_model.dart';

/// Details reference the authoritative catalogue snapshot, not another copy.
final serviceDetailsProvider = Provider.autoDispose
    .family<AsyncValue<ServiceModel?>, String>((ref, id) {
      return ref.watch(catalogControllerProvider).whenData((catalog) {
        for (final service in catalog.services) {
          if (service.id == id) return service;
        }
        return null;
      });
    });
