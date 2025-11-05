import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminder_model.dart';
import '../data/reminders_repository.dart';
import 'reminders_list_controller.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/local_notification_service.dart';

class ReminderCrudController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(ReminderCreateInput input) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(remindersRepositoryProvider);
      final reminder = await repo.createReminder(input);

      // Schedule local notification if has due date
      if (reminder.dueAt != null) {
        final notificationService = ref.read(localNotificationServiceProvider);
        await notificationService.scheduleReminderNotification(
          reminderId: reminder.id,
          title: 'Reminder: ${reminder.title}',
          body: reminder.note ?? 'Upcoming reminder in 10 minutes',
          scheduledTime: reminder.dueAt!,
        );
      }

      ref.read(notificationServiceProvider).notifyNewNotification();
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
      final reminder = await repo.updateReminder(id, input);

      // Reschedule notification
      final notificationService = ref.read(localNotificationServiceProvider);
      await notificationService.cancelNotification(id);

      if (reminder.dueAt != null && reminder.status == ReminderStatus.pending) {
        await notificationService.scheduleReminderNotification(
          reminderId: reminder.id,
          title: 'Reminder: ${reminder.title}',
          body: reminder.note ?? 'Upcoming reminder in 10 minutes',
          scheduledTime: reminder.dueAt!,
        );
      }

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

      // Cancel notification
      final notificationService = ref.read(localNotificationServiceProvider);
      await notificationService.cancelNotification(id);

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

      // Cancel notification when marked done
      final notificationService = ref.read(localNotificationServiceProvider);
      await notificationService.cancelNotification(id);

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
