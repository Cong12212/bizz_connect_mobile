import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _loading = true;
  bool _saving = false;
  String? _err;
  Me? _me;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final me = await repo.getMe();
      _me = me;
      _name.text = me.name ?? '';
      _email.text = me.email ?? '';
    } catch (e) {
      _err = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_me == null) return;
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final updated = await repo.updateMe(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text.trim().isEmpty ? null : _password.text.trim(),
      );
      _me = updated;
      _password.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved!')));
      }
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.logout();
    if (!mounted) return;
    // Điều hướng tuỳ router của bạn, ví dụ:
    // context.go('/auth');
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        : _me == null
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _err ?? 'No user data',
              style: const TextStyle(color: Colors.red),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _f('Name', _name, requiredField: true),
                _f(
                  'Email',
                  _email,
                  requiredField: true,
                  keyboardType: TextInputType.emailAddress,
                ),
                _f('Password (optional)', _password, obscure: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                      ),
                      child: const Text('Log out'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save changes'),
                    ),
                  ],
                ),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ListTile(
                  tileColor: Color(0xFFF8FAFC),
                  title: Text(
                    'Profile',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _f(
    String label,
    TextEditingController c, {
    bool requiredField = false,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
