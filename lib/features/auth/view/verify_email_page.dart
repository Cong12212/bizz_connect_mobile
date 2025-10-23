import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controller/auth_controller.dart';

class VerifyEmailPage extends ConsumerWidget {
  const VerifyEmailPage({super.key, this.emailArg});
  final String? emailArg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final email = emailArg ?? state.email;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Verify email',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ), // ⬅ giống Login/Signup
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ), // ⬅ giống Login/Signup
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 72),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to ${email ?? 'your email'}.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    /* optional: mở app mail */
                  },
                  child: const Text('Open email app'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => ref
                      .read(authControllerProvider.notifier)
                      .resendEmail(email),
                  child: const Text('Resend email'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).refreshMe();
                    // redirect guard sẽ tự chuyển /home nếu đã verified
                  },
                  child: const Text("I've verified – Refresh"),
                ),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Change email address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
