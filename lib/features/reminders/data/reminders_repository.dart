import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './reminder_model.dart';
import 'package:bizz_connect_mobile/core/models/pagination.dart';
import '../../contacts/data/contacts_repository.dart'
    show dioProvider, apiBaseUrlProvider;

/// Provider
final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final base = ref.watch(apiBaseUrlProvider);
  return RemindersRepository(dio, base);
});

class RemindersRepository {
  RemindersRepository(this._dio, this._baseUrl);
  final Dio _dio;
  final String _baseUrl;

  /// ================= Helpers =================
  String? _iso(DateTime? dt) => dt?.toIso8601String();

  Map<String, dynamic> _unwrapData(Map<String, dynamic> map) {
    // Cho phép backend trả {"data": {...}} hoặc {...}
    if (map.containsKey('data') && map['data'] is Map<String, dynamic>) {
      return map['data'] as Map<String, dynamic>;
    }
    return map;
  }

  /// ================= List / CRUD =================

  Future<Paginated<Reminder>> listReminders({
    ReminderStatus? status,
    DateTime? before,
    DateTime? after,
    bool? overdue,
    int? contactId,
    int? page,
    int? perPage,
  }) async {
    final p = <String, dynamic>{};
    if (status != null) p['status'] = status.name;
    if (before != null) p['before'] = _iso(before);
    if (after != null) p['after'] = _iso(after);
    if (overdue == true) p['overdue'] = '1';
    if (contactId != null) p['contact_id'] = contactId;
    if (page != null) p['page'] = page;
    if (perPage != null) p['per_page'] = perPage;

    final res = await _dio.get('/reminders', queryParameters: p);
    return Paginated.fromJson(
      res.data as Map<String, dynamic>,
      (obj) => Reminder.fromJson(obj as Map<String, dynamic>),
    );
  }

  Future<Reminder> getReminder(int id) async {
    final res = await _dio.get('/reminders/$id');
    final map = _unwrapData(res.data as Map<String, dynamic>);
    return Reminder.fromJson(map);
  }

  Future<Reminder> createReminder(ReminderCreateInput input) async {
    final res = await _dio.post('/reminders', data: jsonEncode(input.toJson()));
    final map = _unwrapData(res.data as Map<String, dynamic>);
    return Reminder.fromJson(map);
  }

  Future<Reminder> updateReminder(int id, ReminderUpdateInput input) async {
    final res = await _dio.patch(
      '/reminders/$id',
      data: jsonEncode(input.toJson()),
    );
    final map = _unwrapData(res.data as Map<String, dynamic>);
    return Reminder.fromJson(map);
  }

  Future<void> deleteReminder(int id) async {
    await _dio.delete('/reminders/$id');
  }

  Future<Reminder> markReminderDone(int id) async {
    final res = await _dio.post('/reminders/$id/done');
    final map = _unwrapData(res.data as Map<String, dynamic>);
    return Reminder.fromJson(map);
  }

  /// ================= Bulk =================

  Future<int> bulkUpdateReminderStatus(
    List<int> ids,
    ReminderStatus status,
  ) async {
    final res = await _dio.post(
      '/reminders/bulk-status',
      data: jsonEncode({'ids': ids, 'status': status.name}),
    );
    final map = res.data as Map<String, dynamic>;
    // API trả { updated: number }
    return (map['updated'] ?? 0) as int;
  }

  Future<int> bulkDeleteReminders(List<int> ids) async {
    final res = await _dio.post(
      '/reminders/bulk-delete',
      data: jsonEncode({'ids': ids}),
    );
    final map = res.data as Map<String, dynamic>;
    // API trả { deleted: number }
    return (map['deleted'] ?? 0) as int;
  }

  /// ================= Edges (pivot) =================

  Future<Paginated<ReminderEdge>> listReminderEdges({
    ReminderStatus? status,
    DateTime? before,
    DateTime? after,
    bool? overdue,
    int? contactId,
    int? page,
    int? perPage,
  }) async {
    final p = <String, dynamic>{};
    if (status != null) p['status'] = status.name;
    if (before != null) p['before'] = _iso(before);
    if (after != null) p['after'] = _iso(after);
    if (overdue == true) p['overdue'] = '1';
    if (contactId != null) p['contact_id'] = contactId;
    if (page != null) p['page'] = page;
    if (perPage != null) p['per_page'] = perPage;

    final res = await _dio.get('/reminders/pivot', queryParameters: p);
    return Paginated.fromJson(
      res.data as Map<String, dynamic>,
      (obj) => ReminderEdge.fromJson(obj as Map<String, dynamic>),
    );
  }

  /// Detach 1 quan hệ contact↔reminder (không xoá reminder)
  Future<void> detachReminderContact(int reminderId, int contactId) async {
    await _dio.delete('/reminders/$reminderId/contacts/$contactId');
  }
}
