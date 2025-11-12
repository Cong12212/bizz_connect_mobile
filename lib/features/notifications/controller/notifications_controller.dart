import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../data/notification_models.dart';
import '../data/notifications_repository.dart';
import 'unread_count_provider.dart';

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
  NotificationsController(this._ref) : super(const NotificationsState()) {
    _setupListeners();
  }

  final Ref _ref;
  StreamSubscription? _newNotificationSubscription;
  StreamSubscription? _markReadSubscription;

  NotificationsRepository get _repo =>
      _ref.read(notificationsRepositoryProvider);

  void _setupListeners() {
    final notificationService = _ref.read(notificationServiceProvider);

    // Listen for new notifications
    _newNotificationSubscription = notificationService.onNewNotification.listen(
      (_) {
        loadSilent();
      },
    );

    // Listen for mark read events
    _markReadSubscription = notificationService.onMarkRead.listen((id) {
      _updateNotificationStatus(id, 'read');
    });
  }

  void _updateNotificationStatus(int id, String status) {
    state = state.copyWith(
      items: state.items.map((n) {
        if (n.id == id) {
          return n.copyWith(status: status, readAt: DateTime.now());
        }
        return n;
      }).toList(),
    );
  }

  Future<void> loadSilent() async {
    // Load without showing loading indicator
    try {
      final items = await _repo.getNotifications(scope: state.scope, limit: 50);
      state = state.copyWith(items: items);
    } catch (e) {
      debugPrint('Silent refresh failed: $e');
    }
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final items = await _repo.getNotifications(scope: state.scope, limit: 50);
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false);
      debugPrint('Load failed: $e');
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

  Future<void> markRead(int notificationId) async {
    try {
      await _repo.bulkRead([notificationId]);

      // Update local state immediately
      state = state.copyWith(
        items: state.items.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(status: 'read', readAt: DateTime.now());
          }
          return n;
        }).toList(),
      );

      // Notify other parts of app
      _ref.read(notificationServiceProvider).notifyMarkRead(notificationId);

      // Immediately refresh the unread count badge
      _ref.invalidate(unreadNotificationsCountProvider);
    } catch (e) {
      debugPrint('Mark read failed: $e');
    }
  }

  Future<void> bulkRead() async {
    if (state.selected.isEmpty) return;

    final selectedIds = state.selected.toList();

    try {
      await _repo.bulkRead(selectedIds);

      // Update local state immediately
      state = state.copyWith(
        items: state.items.map((n) {
          if (selectedIds.contains(n.id)) {
            return n.copyWith(status: 'read', readAt: DateTime.now());
          }
          return n;
        }).toList(),
        selected: {},
      );

      // Notify for each marked notification
      for (final id in selectedIds) {
        _ref.read(notificationServiceProvider).notifyMarkRead(id);
      }

      // Immediately refresh the unread count badge
      _ref.invalidate(unreadNotificationsCountProvider);
    } catch (e) {
      debugPrint('Bulk read failed: $e');
    }
  }

  @override
  void dispose() {
    _newNotificationSubscription?.cancel();
    _markReadSubscription?.cancel();
    super.dispose();
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>(
      (ref) => NotificationsController(ref),
    );
