class Paginated<T> {
  final List<T> data;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  Paginated({
    required this.data,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory Paginated.empty() {
    return Paginated<T>(
      data: const [],
      total: 0,
      perPage: 0,
      currentPage: 1,
      lastPage: 1,
    );
  }

  static Paginated<R> fromJson<R>(
    Map<String, dynamic> j,
    R Function(Object?) mapItem,
  ) {
    // Handle both snake_case and camelCase from API
    final perPageValue = j['per_page'] ?? j['perPage'] ?? 0;
    final currentPageValue = j['current_page'] ?? j['currentPage'] ?? 1;
    final lastPageValue = j['last_page'] ?? j['lastPage'] ?? 1;

    return Paginated<R>(
      data: (j['data'] as List? ?? []).map(mapItem).toList(),
      total: j['total'] as int? ?? 0,
      perPage: perPageValue as int,
      currentPage: currentPageValue as int,
      lastPage: lastPageValue as int,
    );
  }
}
