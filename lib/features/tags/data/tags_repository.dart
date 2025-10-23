import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizz_connect_mobile/core/models/pagination.dart';
import '../../contacts/data/contacts_repository.dart'
    show dioProvider, apiBaseUrlProvider;
import 'tag_models.dart';

final tagsRepositoryProvider = Provider<TagsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final base = ref.watch(apiBaseUrlProvider);
  return TagsRepository(dio, base);
});

class TagsRepository {
  TagsRepository(this._dio, this._baseUrl);
  final Dio _dio;
  final String _baseUrl;

  Future<Paginated<Tag>> listTags({String? q, int? page}) async {
    final p = <String, dynamic>{};
    if (q != null && q.trim().isNotEmpty) p['q'] = q.trim();
    if (page != null) p['page'] = page;

    final res = await _dio.get('/tags', queryParameters: p);
    return Paginated.fromJson(
      res.data as Map<String, dynamic>,
      (obj) => Tag.fromJson(obj as Map<String, dynamic>),
    );
  }

  Future<Tag> createTag(String name) async {
    final res = await _dio.post('/tags', data: jsonEncode({'name': name}));
    final map = res.data as Map<String, dynamic>;
    return Tag.fromJson((map['data'] ?? map) as Map<String, dynamic>);
  }

  Future<Tag> renameTag(int id, String name) async {
    final res = await _dio.put('/tags/$id', data: jsonEncode({'name': name}));
    final map = res.data as Map<String, dynamic>;
    return Tag.fromJson((map['data'] ?? map) as Map<String, dynamic>);
  }

  Future<void> deleteTag(int id) async {
    await _dio.delete('/tags/$id');
  }
}
