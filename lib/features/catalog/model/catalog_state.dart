import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';

class CatalogState {
  const CatalogState({
    this.services = const [],
    this.updatedAt,
    this.errorCode,
    this.refreshing = false,
  });
  final List<ServiceModel> services;
  final DateTime? updatedAt;
  final String? errorCode;
  final bool refreshing;

  bool isFreshAt(DateTime now) {
    final updated = updatedAt;
    if (updated == null || updated.isAfter(now)) return false;
    return now.difference(updated) < const Duration(hours: 6);
  }

  CatalogState copyWith({
    List<ServiceModel>? services,
    String? errorCode,
    bool clearError = false,
    bool? refreshing,
  }) => CatalogState(
    services: services ?? this.services,
    updatedAt: updatedAt,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
    refreshing: refreshing ?? this.refreshing,
  );
}
