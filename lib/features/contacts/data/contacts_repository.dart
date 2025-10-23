// lib/features/contacts/data/contacts_repository.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../core/constants.dart';
import 'models.dart';
import 'package:bizz_connect_mobile/core/models/pagination.dart';

/// Base URL lấy từ constant (có thể override ở ProviderScope)
final apiBaseUrlProvider = Provider<String>((_) => AppConst.apiBaseUrl);

final dioProvider = Provider<Dio>((ref) {
  final base = ref.watch(apiBaseUrlProvider);
  final dio = Dio(BaseOptions(baseUrl: base));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (opt, handler) {
        final token = ref.read(authControllerProvider).token;
        if (token != null && token.isNotEmpty) {
          opt.headers['Authorization'] = 'Bearer $token';
        }
        opt.headers['Content-Type'] = 'application/json';
        handler.next(opt);
      },
    ),
  );
  return dio;
});

class ContactsRepository {
  ContactsRepository(this._dio, this._baseUrl);
  final Dio _dio;
  final String _baseUrl; // <— giữ lại để build absolute URL khi cần

  Map<String, dynamic> _toNulls(Map<String, dynamic> m) =>
      m.map((k, v) => MapEntry(k, (v is String && v.isEmpty) ? null : v));

  Future<Paginated<Contact>> listContacts({
    String? q,
    int? page,
    int? perPage,
    String? sort, // "name" | "-name" | "id" | "-id"
    List<int>? tagIds,
    List<String>? tags,
    String? tagMode, // "any" | "all"
    int? withoutTagId,
    String? withoutTagName,
    List<int>? excludeIds,
    bool? withoutReminder,
    String? remStatus, // "pending" | "done" | "skipped" | "cancelled"
    String? remAfter,
    String? remBefore,
  }) async {
    final p = <String, dynamic>{};
    if (q?.isNotEmpty == true) p['q'] = q;
    if (page != null) p['page'] = page;
    if (perPage != null) p['per_page'] = perPage;
    if (sort != null) p['sort'] = sort;
    if (tagIds != null && tagIds.isNotEmpty) p['tag_ids'] = tagIds.join(',');
    if (tags != null && tags.isNotEmpty) p['tags'] = tags.join(',');
    if (tagMode != null) p['tag_mode'] = tagMode;
    if (withoutTagId != null) p['without_tag'] = withoutTagId;
    if (withoutTagName?.isNotEmpty == true) p['without_tag'] = withoutTagName;
    if (excludeIds != null && excludeIds.isNotEmpty) {
      p['exclude_ids'] = excludeIds.join(',');
    }
    if (withoutReminder == true) {
      p['without_reminder'] = 1;
      if (remStatus != null) p['status'] = remStatus;
      if (remAfter != null) p['after'] = remAfter;
      if (remBefore != null) p['before'] = remBefore;
    }

    final res = await _dio.get('/contacts', queryParameters: p);
    return Paginated.fromJson(
      res.data as Map<String, dynamic>,
      (obj) => Contact.fromJson(obj as Map<String, dynamic>),
    );
  }

  Future<Paginated<Contact>> listRecentContacts({String q = ''}) async {
    final res = await _dio.get(
      '/contacts',
      queryParameters: {'per_page': 4, if (q.trim().isNotEmpty) 'q': q.trim()},
    );
    return Paginated.fromJson(
      res.data as Map<String, dynamic>,
      (obj) => Contact.fromJson(obj as Map<String, dynamic>),
    );
  }

  Future<Contact> getContact(int id) async {
    final res = await _dio.get('/contacts/$id');
    final map = res.data as Map<String, dynamic>;
    final data = (map['data'] ?? map) as Map<String, dynamic>;
    return Contact.fromJson(data);
  }

  Future<Contact> createContact(Map<String, dynamic> payload) async {
    final res = await _dio.post(
      '/contacts',
      data: jsonEncode(_toNulls(payload)),
    );
    return Contact.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<Contact> updateContact(int id, Map<String, dynamic> payload) async {
    final res = await _dio.put(
      '/contacts/$id',
      data: jsonEncode(_toNulls(payload)),
    );
    return Contact.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteContact(int id) async {
    await _dio.delete('/contacts/$id');
  }

  Future<Contact?> attachTags(
    int contactId, {
    List<int>? ids,
    List<String>? names,
  }) async {
    final body = <String, dynamic>{};
    if (ids != null) body['ids'] = ids;
    if (names != null) body['names'] = names;

    final res = await _dio.post(
      '/contacts/$contactId/tags',
      data: jsonEncode(body),
    );
    if (res.statusCode == 204 ||
        res.data == null ||
        (res.data is String && (res.data as String).isEmpty)) {
      return null;
    }

    // { data: {...} } hoặc {...}
    if (res.data is Map<String, dynamic>) {
      final map = res.data as Map<String, dynamic>;
      final data = (map['data'] ?? map) as Map<String, dynamic>;
      return Contact.fromJson(data);
    }

    return null;
  }

  Future<Contact?> detachTag(int contactId, int tagId) async {
    final res = await _dio.delete('/contacts/$contactId/tags/$tagId');

    if (res.statusCode == 204 ||
        res.data == null ||
        (res.data is String && (res.data as String).isEmpty)) {
      return null;
    }
    if (res.data is Map<String, dynamic>) {
      final map = res.data as Map<String, dynamic>;
      final data = (map['data'] ?? map) as Map<String, dynamic>;
      return Contact.fromJson(data);
    }
    return null;
  }

  /// Trả về **absolute URL** cho export (mở bằng url_launcher, tải file…)
  String exportContactsUrl({
    String? q,
    String? sort,
    List<int>? tagIds,
    List<String>? tags,
    String? tagMode,
    List<int>? ids,
    String format = 'xlsx',
  }) {
    final p = <String, dynamic>{
      'format': format,
      if (q?.isNotEmpty == true) 'q': q,
      if (sort != null) 'sort': sort,
      if (tagIds != null && tagIds.isNotEmpty) 'tag_ids': tagIds.join(','),
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      if (tagMode != null) 'tag_mode': tagMode,
      if (ids != null && ids.isNotEmpty) 'ids': ids.join(','),
    };
    final qs = p.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent('${e.value}')}',
        )
        .join('&');

    // đảm bảo không double-slash
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return '$base/contacts/export?$qs';
  }

  Future<Response> importContacts(MultipartFile file, {String matchBy = 'id'}) {
    final form = FormData.fromMap({'file': file, 'match_by': matchBy});
    return _dio.post('/contacts/import', data: form);
  }
}

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final base = ref.watch(apiBaseUrlProvider);
  return ContactsRepository(dio, base);
});
