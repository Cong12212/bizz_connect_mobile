import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../controller/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});
  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool agree = true; // tick sẵn cho nhanh dev

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sign Up', style: TextStyle(color: Colors.black)),
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
                    'Create your account',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _name,
                    label: 'Full name',
                    validator: V.required,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _email,
                    label: 'Work email',
                    keyboardType: TextInputType.emailAddress,
                    validator: V.email,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _pass,
                    label: 'Password',
                    obscure: true,
                    validator: V.min6,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _confirm,
                    label: 'Confirm password',
                    obscure: true,
                    validator: (v) {
                      if (V.min6(v) != null) return 'Min 6 chars';
                      if (v != _pass.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: agree,
                        onChanged: (v) => setState(() => agree = v ?? false),
                      ),
                      const Flexible(
                        child: Text('I agree to the Terms & Privacy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    text: 'Create account',
                    loading: state.loading,
                    onPressed: !agree
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signUp(
                                    _name.text.trim(),
                                    _email.text.trim(),
                                    _pass.text,
                                  );
                              final err = ref
                                  .read(authControllerProvider)
                                  .error;
                              if (mounted && err == null) {
                                // chuyển sang verify, mang theo email để hiển thị/resend
                                context.go(
                                  '/verify',
                                  extra: _email.text.trim(),
                                );
                              } else if (err != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(err)));
                              }
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Already have an account? Sign in'),
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
