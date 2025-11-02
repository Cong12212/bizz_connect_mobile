import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contacts_repository.dart'
    show dioProvider; // dùng chung Dio có gắn token

class GeoItem {
  final int id;
  final String code;
  final String name;
  GeoItem({required this.id, required this.code, required this.name});

  factory GeoItem.fromJson(Map<String, dynamic> j) => GeoItem(
    id: j['id'] as int,
    code: j['code'] as String,
    name: j['name'] as String,
  );

  @override
  String toString() => '$name ($code)';
}

class LocationsRepository {
  LocationsRepository(this._dio);
  final Dio _dio;

  Future<List<GeoItem>> getCountries() async {
    final res = await _dio.get('/countries');
    final List data = res.data as List;
    return data
        .map((e) => GeoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GeoItem>> getStates(String countryCode) async {
    final res = await _dio.get('/countries/$countryCode/states');
    final List data = res.data as List;
    return data
        .map((e) => GeoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GeoItem>> getCities(String stateCode) async {
    final res = await _dio.get('/states/$stateCode/cities');
    final List data = res.data as List;
    return data
        .map((e) => GeoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LocationsRepository(dio);
});
