import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';

class AdminServiceFilter {
  const AdminServiceFilter({
    this.search = '',
    this.category = '',
    this.active = '',
  });
  final String search, category, active;
  AdminServiceFilter copyWith({
    String? search,
    String? category,
    String? active,
  }) => AdminServiceFilter(
    search: search ?? this.search,
    category: category ?? this.category,
    active: active ?? this.active,
  );
}

class AdminServiceListState {
  AdminServiceListState({
    required List<AdminService> items,
    required Map<String, String> categories,
    required this.filter,
  }) : items = List.unmodifiable(items),
       categories = Map.unmodifiable(categories);
  final List<AdminService> items;
  final Map<String, String> categories;
  final AdminServiceFilter filter;
}
