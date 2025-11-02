import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../data/settings_repository.dart';
import '../data/models/company_models.dart';

class CompanyEditModal extends ConsumerStatefulWidget {
  const CompanyEditModal({this.company, super.key});

  final Company? company;

  @override
  ConsumerState<CompanyEditModal> createState() => _CompanyEditModalState();
}

class _CompanyEditModalState extends ConsumerState<CompanyEditModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _taxCodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController();

  String? _countryCode;
  String? _stateCode;
  String? _cityCode;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    if (c != null) {
      _nameCtrl.text = c.name;
      _taxCodeCtrl.text = c.taxCode ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _emailCtrl.text = c.email ?? '';
      _websiteCtrl.text = c.website ?? '';
      _descriptionCtrl.text = c.description ?? '';
      _addressDetailCtrl.text = c.address?.addressDetail ?? '';
      _countryCode = c.address?.country?.code;
      _stateCode = c.address?.state?.code;
      _cityCode = c.address?.city?.code;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taxCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressDetailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(settingsRepositoryProvider);
      final formData = CompanyFormData(
        name: _nameCtrl.text.trim(),
        taxCode: _taxCodeCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        addressDetail: _addressDetailCtrl.text.trim(),
        country: _countryCode,
        state: _stateCode,
        city: _cityCode,
      );

      final result = await repo.saveCompany(formData);
      if (mounted) Navigator.pop(context, result);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['message'] ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Company'),
        content: const Text('Are you sure you want to delete this company?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(settingsRepositoryProvider).deleteCompany();
      if (mounted) Navigator.pop(context, null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.transparent,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      const Expanded(
                        child: Text(
                          'Company Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (widget.company != null)
                        IconButton(
                          onPressed: _delete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: controller,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                      ),
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        _field('Company Name *', _nameCtrl, required: true),
                        _field('Tax Code', _taxCodeCtrl),
                        _field(
                          'Phone',
                          _phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          'Email',
                          _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _field(
                          'Website',
                          _websiteCtrl,
                          keyboardType: TextInputType.url,
                        ),
                        _field('Description', _descriptionCtrl, maxLines: 3),
                        _field('Address Detail', _addressDetailCtrl),

                        // TODO: Add Country/State/City dropdowns here
                        // You'll need to create location repository and widgets
                      ],
                    ),
                  ),
                ),

                // Footer
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: FilledButton(
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
                          : Text(
                              widget.company != null
                                  ? 'Update Company'
                                  : 'Create Company',
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            validator: required
                ? (v) => v?.trim().isEmpty ?? true ? '$label is required' : null
                : null,
          ),
        ],
      ),
    );
  }
}
