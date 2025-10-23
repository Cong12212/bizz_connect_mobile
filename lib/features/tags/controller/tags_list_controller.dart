import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tags_repository.dart';
import '../data/tag_models.dart';

class TagsListState {
  final String q;
  final int page;
  final bool loading;
  final String? error;
  final List<Tag> items;
  final int total;
  final int last;

  const TagsListState({
    this.q = '',
    this.page = 1,
    this.loading = false,
    this.error,
    this.items = const [],
    this.total = 0,
    this.last = 1,
  });

  TagsListState copyWith({
    String? q,
    int? page,
    bool? loading,
    String? error,
    List<Tag>? items,
    int? total,
    int? last,
  }) => TagsListState(
    q: q ?? this.q,
    page: page ?? this.page,
    loading: loading ?? this.loading,
    error: error,
    items: items ?? this.items,
    total: total ?? this.total,
    last: last ?? this.last,
  );
}

class TagsListController extends AutoDisposeNotifier<TagsListState> {
  Timer? _debounce;

  TagsRepository get repo => ref.read(tagsRepositoryProvider);

  @override
  TagsListState build() {
    Future.microtask(_fetch);
    ref.onDispose(() => _debounce?.cancel());
    return const TagsListState();
  }

  Future<void> load() => _fetch();

  Future<void> _fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await repo.listTags(q: state.q, page: state.page);
      state = state.copyWith(
        loading: false,
        items: res.data,
        total: res.total,
        last: res.lastPage,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  void setQuery(String q) {
    _debounce?.cancel();
    state = state.copyWith(q: q, page: 1);
    _debounce = Timer(const Duration(milliseconds: 350), _fetch);
  }

  void setPage(int p) {
    state = state.copyWith(page: p);
    _fetch();
  }

  Future<void> create(String name) async {
    final created = await repo.createTag(name.trim());
    // thêm đầu danh sách
    state = state.copyWith(
      items: [created, ...state.items],
      total: state.total + 1,
    );
  }

  Future<void> rename(int id, String name) async {
    // optimistic
    final items = [...state.items];
    final i = items.indexWhere((t) => t.id == id);
    if (i >= 0) {
      final old = items[i].name;
      items[i].name = name;
      state = state.copyWith(items: items);
      try {
        final saved = await repo.renameTag(id, name);
        items[i] = saved;
        state = state.copyWith(items: items);
      } catch (_) {
        items[i].name = old;
        state = state.copyWith(items: items);
        rethrow;
      }
    }
  }

  Future<void> remove(int id) async {
    await repo.deleteTag(id);
    state = state.copyWith(
      items: state.items.where((t) => t.id != id).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
    );
  }

  Future<void> reload() => _fetch();
}

final tagsListControllerProvider =
    AutoDisposeNotifierProvider<TagsListController, TagsListState>(
      TagsListController.new,
    );
