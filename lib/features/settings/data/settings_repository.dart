import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../contacts/data/contacts_repository.dart'
    show dioProvider, apiBaseUrlProvider;

class Me {
  final int id;
  final String? name;
  final String? email;

  Me({required this.id, this.name, this.email});

  factory Me.fromJson(Map<String, dynamic> j) => Me(
    id: j['id'] as int,
    name: j['name'] as String?,
    email: j['email'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final base = ref.watch(apiBaseUrlProvider);
  return SettingsRepository(dio, base);
});

class SettingsRepository {
  SettingsRepository(this._dio, this._baseUrl);
  final Dio _dio;
  final String _baseUrl;

  Future<Me> getMe() async {
    final res = await _dio.get('/me');
    final map = (res.data as Map<String, dynamic>);
    return Me.fromJson(map['data'] ?? map);
  }

  Future<Me> updateMe({
    required String name,
    required String email,
    String? password,
  }) async {
    final payload = <String, dynamic>{'name': name, 'email': email};
    if (password != null && password.trim().isNotEmpty) {
      payload['password'] = password.trim();
    }
    final res = await _dio.put('/me', data: jsonEncode(payload));
    final map = (res.data as Map<String, dynamic>);
    return Me.fromJson(map['data'] ?? map);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    // Token cleanup (tùy nơi bạn set header Authorization)
    _dio.options.headers.remove('Authorization');
  }
}
