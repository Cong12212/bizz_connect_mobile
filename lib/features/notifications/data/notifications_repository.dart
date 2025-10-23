import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../contacts/data/contacts_repository.dart'
    show dioProvider, apiBaseUrlProvider;
import 'notification_models.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  final base = ref.watch(apiBaseUrlProvider);
  return NotificationsRepository(dio, base);
});

class NotificationsRepository {
  NotificationsRepository(this._dio, this._baseUrl);
  final Dio _dio;
  final String _baseUrl;

  Future<List<AppNotification>> list({
    NotificationScope scope = NotificationScope.all,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '/notifications',
      queryParameters: {'scope': scope.key, 'limit': limit},
    );
    final list = (res.data['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return list.map(AppNotification.fromJson).toList();
  }

  Future<AppNotification> markRead(int id) async {
    final res = await _dio.post('/notifications/$id/read');
    final map = (res.data as Map<String, dynamic>);
    return AppNotification.fromJson(map['data'] ?? map);
  }

  Future<AppNotification> markDone(int id) async {
    final res = await _dio.post('/notifications/$id/done');
    final map = (res.data as Map<String, dynamic>);
    return AppNotification.fromJson(map['data'] ?? map);
  }

  Future<int> bulkRead(List<int> ids) async {
    final res = await _dio.post(
      '/notifications/bulk-read',
      data: jsonEncode({'ids': ids}),
    );
    return (res.data['updated'] ?? 0) as int;
  }

  Future<void> deleteOne(int id) async {
    await _dio.delete('/notifications/$id');
  }
}
