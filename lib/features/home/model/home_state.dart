class HomeState {
  const HomeState({this.query = '', this.categoryId});
  final String query;
  final String? categoryId;
  bool get filtered => query.trim().isNotEmpty || categoryId != null;
  HomeState copyWith({
    String? query,
    String? categoryId,
    bool clearCategory = false,
  }) => HomeState(
    query: query ?? this.query,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
  );
}
