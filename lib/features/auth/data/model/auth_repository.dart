import 'package:dio/dio.dart';
import 'package:bizz_connect_mobile/core/networks/api_client.dart';
import '../model/user.dart';

class AuthRepository {
  final _api = ApiClient();

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _api.dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = (res.data is Map) ? res.data['token'] as String? : null;
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        error: 'Token not found',
      );
    }
    _api.setToken(token);
    return token;
  }

  /// GET /auth/me  (Sanctum: routes/api.php -> Route::middleware('auth:sanctum')->get('/auth/me', ...))
  /// Expect: { id, name, email, email_verified_at: "2025-08-01T..." | null }
  Future<({String email, bool verified})> me() async {
    final res = await _api.dio.get('/auth/me');
    final m = res.data as Map;
    final email = (m['email'] ?? '') as String;
    final verified =
        m['email_verified_at'] != null &&
        (m['email_verified_at'] as String).isNotEmpty;
    return (email: email, verified: verified);
  }

  Future<void> resendEmailVerification({String? email}) async {
    try {
      await _api.dio.post('/email/verification-notification');
    } on DioException {
      if (email != null) {
        await _api.dio.post('/auth/resend-verify', data: {'email': email});
      } else {
        rethrow;
      }
    }
  }

  Future<void> passwordRequest({
    required String email,
    required String newPassword,
  }) async {
    await _api.dio.post(
      '/auth/password/request',
      data: {'email': email, 'new_password': newPassword},
    );
  }

  Future<void> passwordResend(String email) async {
    await _api.dio.post('/auth/password/resend', data: {'email': email});
  }

  Future<void> passwordVerify({
    required String email,
    required String code,
  }) async {
    await _api.dio.post(
      '/auth/password/verify',
      data: {'email': email, 'code': code},
    );
  }

  /// PATCH /auth/me - Update current user profile
  /// Payload: { name?, email?, password? }
  /// Returns: User object
  Future<User> updateMe({String? name, String? email, String? password}) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (password != null) payload['password'] = password;

    final res = await _api.dio.patch('/auth/me', data: payload);

    // Parse response to User model
    final data = res.data as Map<String, dynamic>;
    return User.fromJson(data);
  }
}
