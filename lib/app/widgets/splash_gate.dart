// lib/app/widgets/splash_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controller/auth_controller.dart';

// splash_gate.dart
class SplashGate extends ConsumerWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (!auth.bootstrapped) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loggedIn = (auth.token ?? '').isNotEmpty;
      final verified = auth.isVerified == true;
      final target = !loggedIn ? '/login' : (verified ? '/home' : '/verify');

      final current = GoRouterState.of(context).uri.path;
      if (current != target) context.go(target);
    });

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
