import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStore {
  static const _kToken = 'auth_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    webOptions: WebOptions(dbName: 'biz_connect_store'),
  );

  static Future<void> saveToken(String token) =>
      _storage.write(key: _kToken, value: token);

  static Future<String?> readToken() => _storage.read(key: _kToken);

  static Future<void> clearToken() async {
    await _storage.delete(key: _kToken);
  }

  static Future<void> purgeAll() async {
    if (kIsWeb) {
      // Trên web chỉ xóa token thôi
      await _storage.delete(key: _kToken);
    } else {
      // Native platform xóa tất cả
      await _storage.deleteAll();
    }
  }

  // Xóa method restoreToken vì không phù hợp với static class
  // Nếu cần restore token, dùng saveToken
}
