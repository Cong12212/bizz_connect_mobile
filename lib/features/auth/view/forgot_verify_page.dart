import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../controller/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotVerifyPage extends ConsumerStatefulWidget {
  const ForgotVerifyPage({super.key});

  @override
  ConsumerState<ForgotVerifyPage> createState() => _ForgotVerifyPageState();
}

class _ForgotVerifyPageState extends ConsumerState<ForgotVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reset password',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/forgot'),
            child: const Text('Change email'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the 6-digit code sent to ${state.email ?? 'your email'}.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '6-digit code',
                    ),
                    validator: (v) {
                      if (v == null || v.length != 6) return 'Enter 6 digits';
                      if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Digits only';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Confirm reset',
                    loading: state.loading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      await ref
                          .read(authControllerProvider.notifier)
                          .forgotVerify(_code.text.trim());
                      final err = ref.read(authControllerProvider).error;
                      if (mounted && err == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password has been reset. Please sign in.',
                            ),
                          ),
                        );
                        context.go('/login');
                      } else if (err != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err)));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(authControllerProvider.notifier)
                        .forgotResend(),
                    child: const Text('Resend code'),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
