import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminder_model.dart';
import '../data/reminders_repository.dart';
import 'package:bizz_connect_mobile/core/models/pagination.dart';

/// Bộ lọc cho page
class ReminderFilters {
  final ReminderStatus? status;
  final bool overdue;
  final int? contactId;
  final DateTime? before;
  final DateTime? after;
  final int page;
  final int perPage;

  const ReminderFilters({
    this.status,
    this.overdue = false,
    this.contactId,
    this.before,
    this.after,
    this.page = 1,
    this.perPage = 20,
  });

  ReminderFilters copyWith({
    ReminderStatus? status,
    bool? overdue,
    int? contactId,
    DateTime? before,
    DateTime? after,
    int? page,
    int? perPage,
  }) {
    return ReminderFilters(
      status: status ?? this.status,
      overdue: overdue ?? this.overdue,
      contactId: contactId ?? this.contactId,
      before: before ?? this.before,
      after: after ?? this.after,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}

final reminderFiltersProvider = StateProvider<ReminderFilters>(
  (_) => const ReminderFilters(),
);

/// Danh sách reminders (phân trang)
class RemindersListController extends AsyncNotifier<Paginated<Reminder>> {
  @override
  Future<Paginated<Reminder>> build() async {
    final repo = ref.watch(remindersRepositoryProvider);
    final f = ref.watch(reminderFiltersProvider);
    return repo.listReminders(
      status: f.status,
      before: f.before,
      after: f.after,
      overdue: f.overdue,
      contactId: f.contactId,
      page: f.page,
      perPage: f.perPage,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> goToPage(int page) async {
    final f = ref.read(reminderFiltersProvider);
    ref.read(reminderFiltersProvider.notifier).state = f.copyWith(page: page);
    await refresh();
  }

  Future<void> setStatus(ReminderStatus? s) async {
    final f = ref.read(reminderFiltersProvider);
    ref.read(reminderFiltersProvider.notifier).state = f.copyWith(
      status: s,
      page: 1,
    );
    await refresh();
  }

  Future<void> toggleOverdue() async {
    final f = ref.read(reminderFiltersProvider);
    ref.read(reminderFiltersProvider.notifier).state = f.copyWith(
      overdue: !f.overdue,
      page: 1,
    );
    await refresh();
  }
}

final remindersListProvider =
    AsyncNotifierProvider<RemindersListController, Paginated<Reminder>>(
      () => RemindersListController(),
    );
