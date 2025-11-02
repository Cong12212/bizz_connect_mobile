import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizz_connect_mobile/core/networks/api_client.dart';
import 'package:bizz_connect_mobile/core/torage/secure_storage.dart';
import '../data/model/auth_repository.dart';
import 'auth_state.dart';

final apiClientProvider = Provider((_) => ApiClient());
final authRepoProvider = Provider((ref) => AuthRepository());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.read(authRepoProvider),
      ref.read(apiClientProvider),
    )..bootstrap();
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._api) : super(const AuthState());
  final AuthRepository _repo;
  final ApiClient _api;

  Future<void> bootstrap() async {
    String? token;
    String? email;
    bool? verified;

    try {
      token = await SecureStore.readToken();
      if (token != null && token.isNotEmpty) _api.setToken(token);

      if ((token ?? '').isNotEmpty) {
        try {
          final me = await _repo.me();
          email = me.email;
          verified = me.verified;
        } catch (_) {
          // token không dùng được -> coi như chưa đăng nhập
          await SecureStore.purgeAll();
          _api.setToken(null);
          token = null;
          verified = null;
          email = null;
        }
      } else {
        verified = null;
      }
    } finally {
      state = state.copyWith(
        token: token,
        bootstrapped: true,
        email: email,
        isVerified: verified,
      );
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.register(name: name, email: email, password: password);
      state = state.copyWith(loading: false, email: email, isVerified: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final token = await _repo.login(email: email, password: password);
      await SecureStore.saveToken(token);
      _api.setToken(token);

      final me = await _repo.me();
      state = state.copyWith(
        loading: false,
        token: token,
        email: me.email,
        isVerified: me.verified, // true/false rõ ràng
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await SecureStore.purgeAll();
    _api.setToken(null);
    state = state.copyWith(
      token: null,
      email: null,
      isVerified: null, // trở lại “chưa biết”
      error: null,
    );
  }

  Future<void> resendEmail(String? email) async {
    try {
      await _repo.resendEmailVerification(email: email ?? state.email);
    } catch (_) {}
  }

  Future<void> refreshMe() async {
    try {
      final me = await _repo.me();
      state = state.copyWith(email: me.email, isVerified: me.verified);
    } catch (_) {}
  }

  Future<bool> forgotRequest({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(loading: true, error: null, email: email);
    try {
      await _repo.passwordRequest(email: email, newPassword: newPassword);
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<void> forgotResend() async {
    final email = state.email;
    if (email == null) return;
    try {
      await _repo.passwordResend(email);
    } catch (_) {}
  }

  Future<void> forgotVerify(String code) async {
    final email = state.email;
    if (email == null) {
      state = state.copyWith(error: 'Missing email');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.passwordVerify(email: email, code: code);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void restoreToken(String? token) {
    // Nếu vẫn dùng ở nơi khác: đừng bật bootstrapped ở đây
    state = state.copyWith(token: token);
  }
}
