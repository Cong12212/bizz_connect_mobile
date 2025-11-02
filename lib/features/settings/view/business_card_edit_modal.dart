// lib/features/settings/view/business_card_edit_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../data/settings_repository.dart';
import '../data/models/business_card_models.dart';
import '../data/models/company_models.dart';

class BusinessCardEditModal extends ConsumerStatefulWidget {
  const BusinessCardEditModal({this.card, this.company, super.key});

  final BusinessCard? card;
  final Company? company;

  @override
  ConsumerState<BusinessCardEditModal> createState() =>
      _BusinessCardEditModalState();
}

class _BusinessCardEditModalState extends ConsumerState<BusinessCardEditModal> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController();

  bool _isPublic = true;
  String? _countryCode;
  String? _stateCode;
  String? _cityCode;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    if (c != null) {
      _fullNameCtrl.text = c.fullName;
      _emailCtrl.text = c.email;
      _jobTitleCtrl.text = c.jobTitle ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _mobileCtrl.text = c.mobile ?? '';
      _websiteCtrl.text = c.website ?? '';
      _linkedinCtrl.text = c.linkedin ?? '';
      _notesCtrl.text = c.notes ?? '';
      _addressDetailCtrl.text = c.address?.addressDetail ?? '';
      _isPublic = c.isPublic ?? true;
      _countryCode = c.address?.country?.code;
      _stateCode = c.address?.state?.code;
      _cityCode = c.address?.city?.code;
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _jobTitleCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _websiteCtrl.dispose();
    _linkedinCtrl.dispose();
    _notesCtrl.dispose();
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
      final formData = BusinessCardFormData(
        companyId: widget.company?.id,
        fullName: _fullNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        jobTitle: _jobTitleCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        linkedin: _linkedinCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        isPublic: _isPublic,
        addressDetail: _addressDetailCtrl.text.trim(),
        country: _countryCode,
        state: _stateCode,
        city: _cityCode,
      );

      final result = await repo.saveBusinessCard(formData);

      if (mounted) {
        // Close modal and return result
        Navigator.pop(context, result);
      }
    } on DioException catch (e) {
      // Extract error message from Laravel response
      String errorMsg = 'Save failed';

      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message')) {
          errorMsg = data['message'].toString();
        } else if (data.containsKey('error')) {
          errorMsg = data['error'].toString();
        }
      }

      setState(() => _error = errorMsg);
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
        title: const Text('Delete Business Card'),
        content: const Text(
          'Are you sure you want to delete this business card?',
        ),
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
      await ref.read(settingsRepositoryProvider).deleteBusinessCard();
      if (mounted) {
        // Return null to indicate deletion
        Navigator.pop(context, null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Delete failed: $e');
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
                          'Business Card',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (widget.card != null)
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

                        // Public toggle
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Make card public',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Allow others to view and connect',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isPublic,
                                onChanged: (v) => setState(() => _isPublic = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (widget.company != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Company: ${widget.company!.name}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        _field('Full Name *', _fullNameCtrl, required: true),
                        _field(
                          'Email *',
                          _emailCtrl,
                          required: true,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _field('Job Title', _jobTitleCtrl),
                        _field(
                          'Phone',
                          _phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          'Mobile',
                          _mobileCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          'Website',
                          _websiteCtrl,
                          keyboardType: TextInputType.url,
                        ),
                        _field(
                          'LinkedIn',
                          _linkedinCtrl,
                          keyboardType: TextInputType.url,
                        ),
                        _field('Notes', _notesCtrl, maxLines: 3),
                        _field('Address Detail', _addressDetailCtrl),

                        // TODO: Add Country/State/City dropdowns
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
                              widget.card != null
                                  ? 'Update Card'
                                  : 'Create Card',
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
