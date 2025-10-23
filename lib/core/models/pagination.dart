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

  static Paginated<R> fromJson<R>(
    Map<String, dynamic> j,
    R Function(Object?) mapItem,
  ) {
    return Paginated<R>(
      data: (j['data'] as List).map(mapItem).toList(),
      total: j['total'] as int,
      perPage: j['per_page'] as int,
      currentPage: j['current_page'] as int,
      lastPage: j['last_page'] as int,
    );
  }
}
