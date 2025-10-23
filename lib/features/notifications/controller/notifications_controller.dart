import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_models.dart';
import '../data/notifications_repository.dart';

class NotificationsState {
  final List<AppNotification> items;
  final bool loading;
  final String? error;
  final NotificationScope scope;
  final Set<int> selected;

  const NotificationsState({
    this.items = const [],
    this.loading = false,
    this.error,
    this.scope = NotificationScope.all,
    this.selected = const {},
  });

  NotificationsState copyWith({
    List<AppNotification>? items,
    bool? loading,
    String? error,
    NotificationScope? scope,
    Set<int>? selected,
  }) => NotificationsState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    error: error,
    scope: scope ?? this.scope,
    selected: selected ?? this.selected,
  );
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._ref) : super(const NotificationsState());
  final Ref _ref;

  NotificationsRepository get _repo =>
      _ref.read(notificationsRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await _repo.list(scope: state.scope, limit: 20);
      state = state.copyWith(items: items, selected: <int>{});
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  void setScope(NotificationScope scope) {
    state = state.copyWith(scope: scope);
    load();
  }

  void toggleOne(int id, bool checked) {
    final next = {...state.selected};
    if (checked) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(selected: next);
  }

  void toggleAll(List<int> ids, bool checked) {
    final next = {...state.selected};
    if (checked) {
      next.addAll(ids);
    } else {
      ids.forEach(next.remove);
    }
    state = state.copyWith(selected: next);
  }

  Future<void> markRead(int id) async {
    await _repo.markRead(id);
    final items = state.items
        .map(
          (n) => n.id == id
              ? AppNotification.fromJson({
                  ..._toJson(n),
                  'status': 'read',
                  'read_at': DateTime.now().toIso8601String(),
                })
              : n,
        )
        .toList();
    state = state.copyWith(items: items);
  }

  Future<void> bulkRead() async {
    final ids = state.selected.toList();
    if (ids.isEmpty) return;
    await _repo.bulkRead(ids);
    final items = state.items
        .map(
          (n) => state.selected.contains(n.id)
              ? AppNotification.fromJson({
                  ..._toJson(n),
                  'status': 'read',
                  'read_at': DateTime.now().toIso8601String(),
                })
              : n,
        )
        .toList();
    state = state.copyWith(items: items, selected: <int>{});
  }

  Map<String, dynamic> _toJson(AppNotification n) => {
    'id': n.id,
    'owner_user_id': n.ownerUserId,
    'type': n.type,
    'title': n.title,
    'body': n.body,
    'data': n.data,
    'contact_id': n.contactId,
    'reminder_id': n.reminderId,
    'status': n.status,
    'scheduled_at': n.scheduledAt?.toIso8601String(),
    'read_at': n.readAt?.toIso8601String(),
    'created_at': n.createdAt.toIso8601String(),
    'updated_at': n.updatedAt.toIso8601String(),
  };
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>(
      (ref) => NotificationsController(ref),
    );
