import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/contacts_repository.dart';
import '../data/models.dart';

class ScannedContactPreviewDialog extends ConsumerStatefulWidget {
  const ScannedContactPreviewDialog({super.key, required this.scannedData});

  final Map<String, String?> scannedData;

  @override
  ConsumerState<ScannedContactPreviewDialog> createState() =>
      _ScannedContactPreviewDialogState();
}

class _ScannedContactPreviewDialogState
    extends ConsumerState<ScannedContactPreviewDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _jobCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressDetailCtrl;
  late final TextEditingController _cityCodeCtrl;
  late final TextEditingController _stateCodeCtrl;
  late final TextEditingController _countryCodeCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _linkedinCtrl;
  late final TextEditingController _websiteCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    debugPrint('📋 Scanned data received: ${widget.scannedData}');

    // Initialize controllers with scanned data
    _nameCtrl = TextEditingController(text: widget.scannedData['name'] ?? '');
    _jobCtrl = TextEditingController(
      text:
          widget.scannedData['job_title'] ??
          widget.scannedData['jobTitle'] ??
          '',
    );
    _companyCtrl = TextEditingController(
      text: widget.scannedData['company'] ?? '',
    );
    _emailCtrl = TextEditingController(text: widget.scannedData['email'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.scannedData['phone'] ?? '');
    _addressDetailCtrl = TextEditingController(
      text:
          widget.scannedData['address_detail'] ??
          widget.scannedData['addressDetail'] ??
          widget.scannedData['address'] ?? // fallback: chuỗi address cũ
          '',
    );
    _cityCodeCtrl = TextEditingController(
      text:
          widget.scannedData['city'] ??
          widget.scannedData['city_code'] ??
          widget.scannedData['cityCode'] ??
          '',
    );
    _stateCodeCtrl = TextEditingController(
      text:
          widget.scannedData['state'] ??
          widget.scannedData['state_code'] ??
          widget.scannedData['stateCode'] ??
          '',
    );
    _countryCodeCtrl = TextEditingController(
      text:
          widget.scannedData['country'] ??
          widget.scannedData['country_code'] ??
          widget.scannedData['countryCode'] ??
          '',
    );
    _notesCtrl = TextEditingController(
      text: widget.scannedData['notes'] ?? 'Scanned from business card',
    );
    _linkedinCtrl = TextEditingController(
      text:
          widget.scannedData['linkedin_url'] ??
          widget.scannedData['linkedinUrl'] ??
          '',
    );
    _websiteCtrl = TextEditingController(
      text:
          widget.scannedData['website_url'] ??
          widget.scannedData['websiteUrl'] ??
          '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressDetailCtrl.dispose();
    _cityCodeCtrl.dispose();
    _stateCodeCtrl.dispose();
    _countryCodeCtrl.dispose();
    _notesCtrl.dispose();
    _linkedinCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    setState(() => _saving = true);

    try {
      debugPrint('💾 Saving scanned contact...');

      final repo = ref.read(contactsRepositoryProvider);

      // Tạo form theo chuẩn mới; repo sẽ null-hoá chuỗi rỗng bằng _toNulls
      final form = ContactFormData(
        name: _nameCtrl.text.trim(),
        jobTitle: _jobCtrl.text.trim().isEmpty ? null : _jobCtrl.text.trim(),
        company: _companyCtrl.text.trim().isEmpty
            ? null
            : _companyCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),

        // Address chuẩn mới: gửi code để BE map ra address_id
        addressDetail: _addressDetailCtrl.text.trim().isEmpty
            ? null
            : _addressDetailCtrl.text.trim(),
        cityCode: _cityCodeCtrl.text.trim().isEmpty
            ? null
            : _cityCodeCtrl.text.trim(),
        stateCode: _stateCodeCtrl.text.trim().isEmpty
            ? null
            : _stateCodeCtrl.text.trim(),
        countryCode: _countryCodeCtrl.text.trim().isEmpty
            ? null
            : _countryCodeCtrl.text.trim(),
      );

      final contact = await repo.createContactFromForm(form);

      debugPrint('✅ Contact created: ${contact.id}');

      if (mounted) {
        Navigator.pop(context, contact);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving contact: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.preview, color: Color(0xFF0284C7)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Scanned Contact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Please verify and edit the information below',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildField('Name *', _nameCtrl),
                    _buildField('Job Title', _jobCtrl),
                    _buildField('Company', _companyCtrl),
                    _buildField(
                      'Email',
                      _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildField(
                      'Phone',
                      _phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField('Address detail', _addressDetailCtrl),
                    _buildField('City code (e.g. HCM)', _cityCodeCtrl),
                    _buildField('State code (e.g. SG)', _stateCodeCtrl),
                    _buildField('Country code (e.g. VN)', _countryCodeCtrl),
                    _buildField('Notes', _notesCtrl, maxLines: 3),
                    _buildField(
                      'LinkedIn URL',
                      _linkedinCtrl,
                      keyboardType: TextInputType.url,
                    ),
                    _buildField(
                      'Website URL',
                      _websiteCtrl,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveContact,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add, size: 18),
                      label: Text(_saving ? 'Saving...' : 'Add Contact'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final hasValue = controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              if (hasValue) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Detected',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: hasValue
                  ? const Color(0xFFF0F9FF)
                  : const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasValue
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
