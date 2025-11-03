import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../data/settings_repository.dart';
import '../data/settings_state.dart';
import '../data/models/company_models.dart';
import '../widgets/address_form_fields.dart';

class CompanyEditModal extends ConsumerStatefulWidget {
  const CompanyEditModal({this.company, this.isEditing = false, super.key});

  final Company? company;
  final bool isEditing;

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
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.isEditing || widget.company == null;
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

      // Cập nhật provider state (không cần reload page)
      ref.read(companyProvider.notifier).update(result);

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

      // Sửa: dùng clear() thay vì update(null)
      ref.read(companyProvider.notifier).clear();

      if (mounted) Navigator.pop(context, null);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Delete failed: $e');
      }
    }
  }

  String _formatAddress() {
    final c = widget.company;
    if (c?.address == null) return '—';

    final parts = <String>[];
    final detail = c!.address!.addressDetail;
    final city = c.address!.city?.name;
    final state = c.address!.state?.name;
    final country = c.address!.country?.name;

    if ((detail ?? '').trim().isNotEmpty) parts.add(detail!.trim());
    if ((city ?? '').trim().isNotEmpty) parts.add(city!.trim());
    if ((state ?? '').trim().isNotEmpty) parts.add(state!.trim());
    if ((country ?? '').trim().isNotEmpty) parts.add(country!.trim());

    return parts.isEmpty ? '—' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Đóng modal khi tap vùng ngoài
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        // Prevent closing khi tap vào modal content
        onTap: () {},
        child: Container(
          color: Colors.transparent,
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => GestureDetector(
              // Ngăn event bubble lên GestureDetector cha
              onTap: () {},
              child: Container(
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
                          Expanded(
                            child: Text(
                              _isEditMode
                                  ? (widget.company != null
                                        ? 'Edit Company'
                                        : 'Create Company')
                                  : 'Company Details',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!_isEditMode && widget.company != null)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isEditMode = true),
                              child: const Text('Edit'),
                            )
                          else if (_isEditMode && widget.company != null)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isEditMode = false),
                              child: const Text('Cancel'),
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: _isEditMode
                          ? _buildEditForm(controller)
                          : _buildViewMode(controller),
                    ),

                    // Footer
                    if (_isEditMode)
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
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
                      )
                    else
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: FilledButton(
                            onPressed: _delete,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete Company'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(ScrollController controller) {
    return Form(
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
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
          ],

          _field('Company Name *', _nameCtrl, required: true),
          _field('Tax Code', _taxCodeCtrl),
          _field('Phone', _phoneCtrl, keyboardType: TextInputType.phone),
          _field('Email', _emailCtrl, keyboardType: TextInputType.emailAddress),
          _field('Website', _websiteCtrl, keyboardType: TextInputType.url),
          _field('Description', _descriptionCtrl, maxLines: 3),

          // Address fields with dropdowns
          AddressFormFields(
            addressDetailController: _addressDetailCtrl,
            initialCountry: _countryCode,
            initialState: _stateCode,
            initialCity: _cityCode,
            onCountryChanged: (val) => _countryCode = val,
            onStateChanged: (val) => _stateCode = val,
            onCityChanged: (val) => _cityCode = val,
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode(ScrollController controller) {
    final c = widget.company;
    if (c == null) return const SizedBox.shrink();

    Widget _infoRow(String label, String? value) {
      final v = (value ?? '').trim();
      if (v.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Company Name', c.name),
        _infoRow('Tax Code', c.taxCode),
        _infoRow('Phone', c.phone),
        _infoRow('Email', c.email),
        _infoRow('Website', c.website),
        _infoRow('Description', c.description),
        _infoRow('Address', _formatAddress()),
      ],
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
