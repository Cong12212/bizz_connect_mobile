import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/networks/api_client.dart';
import '../../core/torage/secure_storage.dart';
import '../../features/auth/controller/auth_controller.dart';

final appBootstrapperProvider = FutureProvider<void>((ref) async {
  final token =
      await SecureStore.readToken(); // web: IndexedDB, mobile: Keychain/Keystore
  ApiClient().setToken(token); // set vào Dio trước
  ref
      .read(authControllerProvider.notifier)
      .restoreToken(token); // bootstrapped=true
});
