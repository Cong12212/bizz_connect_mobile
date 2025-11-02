// settings/data/settings_repository.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../core/network/dio_client.dart';
import 'package:bizz_connect_mobile/core/networks/api_client.dart';
import 'models/business_card_models.dart';
import 'models/company_models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ApiClient().dio);
});

class SettingsRepository {
  final Dio _dio;

  SettingsRepository(this._dio);

  // ========== USER ME ==========
  Future<MeResponse> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return MeResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<MeResponse> updateMe({
    required String name,
    required String email,
    String? password,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/me',
        data: {
          'name': name,
          'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      return MeResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    }
  }

  // ========== COMPANY ==========
  Future<Company?> getCompany() async {
    try {
      final response = await _dio.get('/company');

      // Handle 204 No Content or null data
      if (response.statusCode == 204) {
        return null;
      }

      // Check if data is null or empty
      if (response.data == null) {
        return null;
      }

      // Check if data is a Map (expected JSON object)
      if (response.data is! Map<String, dynamic>) {
        return null;
      }

      return Company.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) {
        return null;
      }
      if (e.response?.data == null) {
        return null;
      }
      rethrow;
    } catch (e) {
      print('getCompany error: $e');
      rethrow;
    }
  }

  Future<Company> saveCompany(CompanyFormData formData) async {
    try {
      final response = await _dio.post('/company', data: formData.toJson());
      return Company.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCompany() async {
    try {
      await _dio.delete('/company');
    } catch (e) {
      rethrow;
    }
  }

  // ========== BUSINESS CARD ==========
  Future<BusinessCard?> getBusinessCard() async {
    try {
      final response = await _dio.get('/business-card');

      // Handle 204 No Content or null data
      if (response.statusCode == 204) {
        return null;
      }

      // Check if data is null or empty
      if (response.data == null) {
        return null;
      }

      // Check if data is a Map (expected JSON object)
      if (response.data is! Map<String, dynamic>) {
        return null;
      }

      return BusinessCard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Handle 204 from DioException
      if (e.response?.statusCode == 204) {
        return null;
      }
      // Handle null response data
      if (e.response?.data == null) {
        return null;
      }
      rethrow;
    } catch (e) {
      // Log the error for debugging
      print('getBusinessCard error: $e');
      rethrow;
    }
  }

  Future<BusinessCard> saveBusinessCard(BusinessCardFormData formData) async {
    try {
      final response = await _dio.post(
        '/business-card',
        data: formData.toJson(),
      );
      return BusinessCard.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBusinessCard() async {
    try {
      await _dio.delete('/business-card');
    } catch (e) {
      rethrow;
    }
  }
}

// Response model matching your React FE
class MeResponse {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final bool? verified;

  MeResponse({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.verified,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      id: json['id'] as int?,
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      verified: json['verified'] as bool?,
    );
  }
}
