class ServiceFormState {
  ServiceFormState({
    required this.categoryId,
    this.active = true,
    this.featured = false,
    this.error,
    Map<int, String> inclusions = const {},
    Map<String, String> quantities = const {},
  }) : inclusions = Map.unmodifiable(inclusions),
       quantities = Map.unmodifiable(quantities);
  final String categoryId;
  final bool active, featured;
  final String? error;
  final Map<int, String> inclusions;
  final Map<String, String> quantities;
  ServiceFormState copyWith({
    String? categoryId,
    bool? active,
    bool? featured,
    String? error,
    Map<int, String>? inclusions,
    Map<String, String>? quantities,
  }) => ServiceFormState(
    categoryId: categoryId ?? this.categoryId,
    active: active ?? this.active,
    featured: featured ?? this.featured,
    error: error,
    inclusions: inclusions ?? this.inclusions,
    quantities: quantities ?? this.quantities,
  );
}
