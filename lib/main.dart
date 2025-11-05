import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
import 'app/bootstrap/app_bootstrapper.dart';
import 'core/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  runApp(const ProviderScope(child: BizConnectApp()));
}

class BizConnectApp extends ConsumerWidget {
  const BizConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CHỜ hydrate token trước khi tạo router
    final boot = ref.watch(appBootstrapperProvider);

    return boot.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const _Splash(), // splash trống/nhẹ
        theme: _theme,
      ),
      error: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const _Splash(),
        theme: _theme,
      ),
      data: (_) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Biz-Connect',
          theme: _theme,
          routerConfig: router,
        );
      },
    );
  }

  ThemeData get _theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: Brightness.light,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(width: 1.2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        side: const BorderSide(color: Color(0xFF2F2F2F), width: 1),
        foregroundColor: const Color(0xFF2F2F2F),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF2F2F2F)),
    ),
  );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
