import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminder_model.dart';
import '../data/reminders_repository.dart';
import 'reminders_list_controller.dart';
import '../../../core/services/notification_service.dart';

class ReminderCrudController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(ReminderCreateInput input) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(remindersRepositoryProvider);
      await repo.createReminder(input);

      // Trigger notification refresh
      ref.read(notificationServiceProvider).notifyNewNotification();

      // Reload list
      await ref.read(remindersListProvider.notifier).refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateReminder(int id, ReminderUpdateInput input) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(remindersRepositoryProvider);
      await repo.updateReminder(id, input);
      await ref.read(remindersListProvider.notifier).refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(remindersRepositoryProvider);
      await repo.deleteReminder(id);
      await ref.read(remindersListProvider.notifier).refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> markDone(int id) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(remindersRepositoryProvider);
      await repo.markReminderDone(id);
      await ref.read(remindersListProvider.notifier).refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<int> bulkStatus(List<int> ids, ReminderStatus status) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(remindersRepositoryProvider);
      final n = await repo.bulkUpdateReminderStatus(ids, status);
      await ref.read(remindersListProvider.notifier).refresh();
      state = const AsyncData(null);
      return n;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<int> bulkDelete(List<int> ids) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(remindersRepositoryProvider);
      final n = await repo.bulkDeleteReminders(ids);
      await ref.read(remindersListProvider.notifier).refresh();
      state = const AsyncData(null);
      return n;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> detachEdge(int reminderId, int contactId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(remindersRepositoryProvider);
      await repo.detachReminderContact(reminderId, contactId);
      await ref.read(remindersListProvider.notifier).refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final reminderCrudProvider =
    AsyncNotifierProvider<ReminderCrudController, void>(
      () => ReminderCrudController(),
    );
