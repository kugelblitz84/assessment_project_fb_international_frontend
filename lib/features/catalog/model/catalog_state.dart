import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';

class CatalogState {
  const CatalogState({
    this.services = const [],
    this.errorCode,
    this.refreshing = false,
  });
  final List<ServiceModel> services;
  final String? errorCode;
  final bool refreshing;
  CatalogState copyWith({
    List<ServiceModel>? services,
    String? errorCode,
    bool clearError = false,
    bool? refreshing,
  }) => CatalogState(
    services: services ?? this.services,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
    refreshing: refreshing ?? this.refreshing,
  );
}
