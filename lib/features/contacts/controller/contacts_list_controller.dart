// lib/features/contacts/controller/contacts_list_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/contacts_repository.dart';
import '../data/models.dart';

class ContactsListState {
  final String q;
  final int page;
  final int per;
  final String sort;
  final bool loading;
  final String? error;
  final List<Contact> items;
  final int total;
  final int last;

  const ContactsListState({
    this.q = '',
    this.page = 1,
    this.per = 20,
    this.sort = 'name',
    this.loading = false,
    this.error,
    this.items = const [],
    this.total = 0,
    this.last = 1,
  });

  ContactsListState copyWith({
    String? q,
    int? page,
    int? per,
    String? sort,
    bool? loading,
    String? error,
    List<Contact>? items,
    int? total,
    int? last,
  }) => ContactsListState(
    q: q ?? this.q,
    page: page ?? this.page,
    per: per ?? this.per,
    sort: sort ?? this.sort,
    loading: loading ?? this.loading,
    error: error,
    items: items ?? this.items,
    total: total ?? this.total,
    last: last ?? this.last,
  );
}

class ContactsListController extends StateNotifier<ContactsListState> {
  ContactsListController(this.ref) : super(const ContactsListState());
  final Ref ref;
  Timer? _debounce;
  bool _isInitialized = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    // Prevent multiple simultaneous loads
    if (state.loading) return;

    print(
      '[ContactsList] Loading: q="${state.q}", page=${state.page}, sort=${state.sort}',
    );

    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final res = await repo.listContacts(
        q: state.q.isEmpty ? null : state.q,
        page: state.page,
        perPage: state.per,
        sort: state.sort,
      );

      print(
        '[ContactsList] Loaded: ${res.data.length} items, total=${res.total}',
      );

      // Check if still mounted
      if (mounted) {
        state = state.copyWith(
          loading: false,
          items: res.data,
          total: res.total,
          last: res.lastPage,
        );
        _isInitialized = true;
      }
    } catch (e) {
      print('[ContactsList] Error: $e');
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.page >= state.last) return;

    final nextPage = state.page + 1;

    try {
      final repo = ref.read(contactsRepositoryProvider);
      final res = await repo.listContacts(
        q: state.q.isEmpty ? null : state.q,
        page: nextPage,
        perPage: state.per,
        sort: state.sort,
      );

      if (mounted) {
        state = state.copyWith(
          page: nextPage,
          items: [...state.items, ...res.data], // Append items
          total: res.total,
          last: res.lastPage,
        );
      }
    } catch (e) {
      print('[ContactsList] Error loading more: $e');
    }
  }

  void refreshContact(Contact updatedContact) {
    final newItems = state.items.map((c) {
      return c.id == updatedContact.id ? updatedContact : c;
    }).toList();

    state = state.copyWith(items: newItems);
  }

  void setQuery(String q) {
    _debounce?.cancel();

    // Update state immediately to show search text
    state = state.copyWith(q: q, page: 1);

    // Debounce the actual API call
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        load();
      }
    });
  }

  void setSort(String s) {
    if (s == state.sort) return;
    state = state.copyWith(sort: s, page: 1);
    load();
  }

  Future<void> setPage(int p) async {
    if (p == state.page || state.loading) return;
    state = state.copyWith(page: p);
    await load();
  }

  Future<void> deleteContact(int id) async {
    if (state.loading) return;

    final repo = ref.read(contactsRepositoryProvider);
    final prev = state;

    // Optimistic update
    final newItems = state.items.where((c) => c.id != id).toList();
    state = state.copyWith(
      items: newItems,
      total: state.total > 0 ? state.total - 1 : 0,
      error: null,
    );

    try {
      await repo.deleteContact(id);

      // Reload to get accurate data
      await load();

      // If current page is beyond last page, go to last page
      if (mounted && state.page > state.last && state.last > 0) {
        state = state.copyWith(page: state.last);
        await load();
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        state = prev.copyWith(error: e.toString());
      }
    }
  }
}

final contactsListControllerProvider =
    StateNotifierProvider<ContactsListController, ContactsListState>(
      (ref) => ContactsListController(ref),
    );
