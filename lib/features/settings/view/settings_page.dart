// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/settings_repository.dart';
import '../data/models/company_models.dart';
import '../data/models/business_card_models.dart';
import '../widgets/error_box.dart';
import 'company_edit_modal.dart';
import 'business_card_edit_modal.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  Company? _company;
  BusinessCard? _businessCard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);

      // Load data separately to debug
      print('Loading user data...');
      final meData = await settingsRepo.getMe();
      print('User loaded: ${meData.name}');

      print('Loading company data...');
      final companyData = await settingsRepo.getCompany();
      print('Company loaded: ${companyData?.name ?? "null"}');

      print('Loading business card data...');
      final cardData = await settingsRepo.getBusinessCard();
      print('Business card loaded: ${cardData?.fullName ?? "null"}');

      setState(() {
        _nameCtrl.text = meData.name ?? '';
        _emailCtrl.text = meData.email ?? '';
        _company = companyData;
        _businessCard = cardData;
      });
    } on DioException catch (e) {
      print('DioException: ${e.response?.statusCode} - ${e.response?.data}');
      setState(() => _error = _prettyError(e));
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final updated = await settingsRepo.updateMe(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim().isEmpty ? null : _pwdCtrl.text.trim(),
      );

      setState(() {
        _nameCtrl.text = updated.name ?? '';
        _emailCtrl.text = updated.email ?? '';
        _pwdCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      setState(() => _error = _prettyError(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SecureStorage.delete(SecureStorage.keyToken);
      await ref.read(settingsRepositoryProvider).logout();

      if (mounted) context.go('/auth');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  String _prettyError(DioException e) {
    final code = e.response?.statusCode;
    final msg = e.response?.data is Map
        ? (e.response?.data['message']?.toString() ?? e.message ?? '')
        : e.message ?? 'Unknown error';

    if (code == 401) return 'Session expired. Please login again.';
    if (code == 422) return 'Validation error: $msg';
    if (code == 405) return 'Method not allowed. Check API endpoint.';
    return 'Error $code: $msg';
  }

  // --- UI/Helper Methods ---

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade200),
  );

  InputDecoration _input(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Future<void> _openBusinessCardModal() async {
    final result = await showModalBottomSheet<BusinessCard?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BusinessCardEditModal(card: _businessCard, company: _company),
    );

    // Refresh regardless of result (created, updated, or deleted)
    if (mounted) {
      await _load();

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _businessCard == null
                  ? 'Business card created!'
                  : 'Business card updated!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _openCompanyModal() async {
    final result = await showModalBottomSheet<Company?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanyEditModal(company: _company),
    );

    // Refresh regardless of result (created, updated, or deleted)
    if (mounted) {
      await _load();

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _company == null ? 'Company created!' : 'Company updated!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    ErrorBox(message: _error!),
                    const SizedBox(height: 16),
                  ],

                  // ===== Profile Section =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _box(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: _input('Name', Icons.person_outline),
                            textInputAction: TextInputAction.next,
                            validator: (v) => v?.trim().isEmpty ?? true
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _input('Email', Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) => v?.trim().isEmpty ?? true
                                ? 'Email is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: Colors.black87,
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Company =====
                  GestureDetector(
                    onTap: _openCompanyModal,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _box(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.business, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Company',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _company != null
                                    ? Icons.edit_outlined
                                    : Icons.add,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _company?.name ?? 'No company set',
                            style: TextStyle(
                              fontSize: 14,
                              color: _company != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                          if (_company != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Last updated: ${DateTime.parse(_company!.updatedAt).toLocal().toString().split(' ')[0]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Business Card =====
                  GestureDetector(
                    onTap: _openBusinessCardModal,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _box(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Business Card',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _businessCard != null
                                    ? Icons.edit_outlined
                                    : Icons.add,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_businessCard != null) ...[
                            Text(
                              _businessCard!.fullName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_businessCard!.jobTitle != null)
                              Text(
                                _businessCard!.jobTitle!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _businessCard!.isPublic == true
                                      ? Icons.public
                                      : Icons.lock_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _businessCard!.isPublic == true
                                      ? 'Public'
                                      : 'Private',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_businessCard!.viewCount ?? 0} views',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            const Text(
                              'No business card set',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Logout =====
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}
