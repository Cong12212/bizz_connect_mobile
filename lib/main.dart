import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
import 'features/contacts/controller/contacts_list_controller.dart';
import 'features/tags/controller/tags_list_controller.dart';
import 'features/reminders/controller/reminders_controller.dart';

void main() {
  runApp(const ProviderScope(child: BizConnectApp()));
}

class BizConnectApp extends ConsumerWidget {
  const BizConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BizzConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        cardColor: Colors.white,
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
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            foregroundColor: const Color(0xFF374151),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      ),
      routerConfig: router,
      builder: (context, child) {
        return _PreloadWidget(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _PreloadWidget extends ConsumerStatefulWidget {
  const _PreloadWidget({required this.child});
  final Widget child;

  @override
  ConsumerState<_PreloadWidget> createState() => _PreloadWidgetState();
}

class _PreloadWidgetState extends ConsumerState<_PreloadWidget> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Preload providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(contactsListControllerProvider.notifier).load();
        ref.read(tagsListControllerProvider.notifier).load();
        ref.read(remindersControllerProvider.notifier).loadReminders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
