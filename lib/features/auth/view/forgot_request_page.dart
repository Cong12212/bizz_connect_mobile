import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../controller/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotRequestPage extends ConsumerStatefulWidget {
  const ForgotRequestPage({super.key});

  @override
  ConsumerState<ForgotRequestPage> createState() => _ForgotRequestPageState();
}

class _ForgotRequestPageState extends ConsumerState<ForgotRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Forgot password',
          style: TextStyle(color: Colors.black),
        ),
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
                  const Text(
                    'Enter your email and new password. We will send a 6-digit code to verify.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: V.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPass,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                    validator: V.min6,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    validator: (v) {
                      if (V.min6(v) != null) return 'Min 6 chars';
                      if (v != _newPass.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Send code',
                    loading: state.loading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final ok = await ref
                          .read(authControllerProvider.notifier)
                          .forgotRequest(
                            email: _email.text.trim(),
                            newPassword: _newPass.text,
                          );
                      if (!mounted) return;
                      if (ok)
                        context.go('/reset-verify');
                      else {
                        final err =
                            ref.read(authControllerProvider).error ??
                            'Request failed';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err)));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to Sign in'),
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
