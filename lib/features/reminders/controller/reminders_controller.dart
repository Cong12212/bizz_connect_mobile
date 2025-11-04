import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../data/reminders_repository.dart';
import '../data/reminder_model.dart';

// This file exports the reminder controllers for convenience
export 'reminders_list_controller.dart';
export 'reminder_crud_controller.dart';

// Reminders State and Controller
class RemindersState {
  final List<Reminder> items;
  final bool loading;
  final String? error;

  const RemindersState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  RemindersState copyWith({
    List<Reminder>? items,
    bool? loading,
    String? error,
  }) => RemindersState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    error: error,
  );
}

class RemindersController extends StateNotifier<RemindersState> {
  RemindersController(this._ref) : super(const RemindersState());
  final Ref _ref;

  RemindersRepository get _repo => _ref.read(remindersRepositoryProvider);

  Future<void> loadReminders() async {
    state = state.copyWith(loading: true);
    try {
      final paginated = await _repo.listReminders();
      state = state.copyWith(items: paginated.data, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      debugPrint('Load reminders failed: $e');
    }
  }

  Future<Reminder> createReminder(ReminderCreateInput data) async {
    try {
      final reminder = await _repo.createReminder(data);

      state = state.copyWith(items: [reminder, ...state.items]);

      _ref.read(notificationServiceProvider).notifyNewNotification();

      return reminder;
    } catch (e) {
      debugPrint('Create reminder failed: $e');
      rethrow;
    }
  }

  Future<Reminder> updateReminder(int id, ReminderUpdateInput data) async {
    try {
      final reminder = await _repo.updateReminder(id, data);

      state = state.copyWith(
        items: state.items.map((r) => r.id == id ? reminder : r).toList(),
      );

      return reminder;
    } catch (e) {
      debugPrint('Update reminder failed: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await _repo.deleteReminder(id);

      state = state.copyWith(
        items: state.items.where((r) => r.id != id).toList(),
      );
    } catch (e) {
      debugPrint('Delete reminder failed: $e');
      rethrow;
    }
  }
}

final remindersControllerProvider =
    StateNotifierProvider<RemindersController, RemindersState>(
      (ref) => RemindersController(ref),
    );
