import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/location_repository.dart';
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
  // ===== Controllers =====
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

  // ===== Scan dialog dropdown state =====
  String? _countryCode;
  String? _stateCode;
  String? _cityCode;

  List<dynamic> _countries = [];
  List<dynamic> _states = [];
  List<dynamic> _cities = [];

  bool _saving = false;
  bool _loadingGeo = false;

  @override
  void initState() {
    super.initState();

    String pick(List<String> keys) {
      for (final k in keys) {
        final v = widget.scannedData[k];
        if ((v ?? '').toString().trim().isNotEmpty) return v!.trim();
      }
      return '';
    }

    // Parse full address if available
    String addressFull = pick(['addressDetail', 'address_detail', 'address']);
    String? detectedCountry;
    String? detectedState;
    String? detectedCity;
    String? addressDetail;

    // Try to extract location from full address
    if (addressFull.isNotEmpty) {
      debugPrint('📍 Parsing address: $addressFull');

      // Split by comma
      final parts = addressFull
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      debugPrint('📍 Address parts: $parts');

      if (parts.length >= 3) {
        // Assume format: "detail, city, state, country" or "city, state, country"
        detectedCountry = parts.last; // Last is country
        detectedState = parts[parts.length - 2]; // Second last is state
        detectedCity = parts[parts.length - 3]; // Third last is city

        // Remaining parts are address detail
        if (parts.length > 3) {
          addressDetail = parts.sublist(0, parts.length - 3).join(', ');
        }

        debugPrint(
          '📍 Detected - Country: $detectedCountry, State: $detectedState, City: $detectedCity',
        );
        debugPrint('📍 Address detail: $addressDetail');
      }
    }

    // Initialize controllers
    _nameCtrl = TextEditingController(
      text: pick(['name', 'fullName', 'full_name']),
    );
    _jobCtrl = TextEditingController(
      text: pick(['jobTitle', 'job_title', 'position', 'title']),
    );
    _companyCtrl = TextEditingController(
      text: pick(['company', 'organization']),
    );
    _emailCtrl = TextEditingController(text: pick(['email']));
    _phoneCtrl = TextEditingController(
      text: pick(['phone', 'mobile', 'phoneNumber', 'phone_number']),
    );
    _addressDetailCtrl = TextEditingController(text: addressDetail ?? '');
    _notesCtrl = TextEditingController(
      text: pick(['notes', 'note']).isEmpty
          ? 'Scanned from business card'
          : pick(['notes', 'note']),
    );
    _linkedinCtrl = TextEditingController(
      text: pick(['linkedinUrl', 'linkedin_url', 'linkedin']),
    );
    _websiteCtrl = TextEditingController(
      text: pick(['websiteUrl', 'website_url', 'website', 'web']),
    );

    // Priority: explicit fields > detected from address > empty
    final countryValue = pick([
      'countryCode',
      'country_code',
      'countryName',
      'country_name',
      'country',
    ]);
    final stateValue = pick([
      'stateCode',
      'state_code',
      'stateName',
      'state_name',
      'state',
    ]);
    final cityValue = pick([
      'cityCode',
      'city_code',
      'cityName',
      'city_name',
      'city',
    ]);

    _countryCodeCtrl = TextEditingController(
      text: countryValue.isNotEmpty ? countryValue : (detectedCountry ?? ''),
    );
    _stateCodeCtrl = TextEditingController(
      text: stateValue.isNotEmpty ? stateValue : (detectedState ?? ''),
    );
    _cityCodeCtrl = TextEditingController(
      text: cityValue.isNotEmpty ? cityValue : (detectedCity ?? ''),
    );

    _countryCode = _countryCodeCtrl.text.isNotEmpty
        ? _countryCodeCtrl.text
        : null;
    _stateCode = _stateCodeCtrl.text.isNotEmpty ? _stateCodeCtrl.text : null;
    _cityCode = _cityCodeCtrl.text.isNotEmpty ? _cityCodeCtrl.text : null;

    debugPrint('🌍 Initial location:');
    debugPrint('  Country: $_countryCode');
    debugPrint('  State: $_stateCode');
    debugPrint('  City: $_cityCode');

    // Load and match
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCountries();

      if (_countryCode != null && _countries.isNotEmpty) {
        debugPrint('🔍 Matching country: $_countryCode');

        final matched = _countries.firstWhere((c) {
          final code = (c as dynamic).code?.toString().toLowerCase();
          final name = (c as dynamic).name?.toString().toLowerCase();
          final search = _countryCode?.toLowerCase();
          return code == search ||
              name == search ||
              name?.contains(search ?? '') == true;
        }, orElse: () => null);

        if (matched != null && mounted) {
          final newCode = (matched as dynamic).code?.toString();
          debugPrint('✅ Country matched: $newCode');

          setState(() {
            _countryCode = newCode;
            _countryCodeCtrl.text = newCode ?? '';
          });

          if (newCode != null) {
            await _loadStates(newCode);
          }
        } else {
          debugPrint('❌ Country not matched: $_countryCode');
        }
      }

      if (_stateCode != null && _states.isNotEmpty) {
        debugPrint('🔍 Matching state: $_stateCode');

        final matched = _states.firstWhere((s) {
          final code = (s as dynamic).code?.toString().toLowerCase();
          final name = (s as dynamic).name?.toString().toLowerCase();
          final search = _stateCode?.toLowerCase();
          return code == search ||
              name == search ||
              name?.contains(search ?? '') == true;
        }, orElse: () => null);

        if (matched != null && mounted) {
          final newCode = (matched as dynamic).code?.toString();
          debugPrint('✅ State matched: $newCode');

          setState(() {
            _stateCode = newCode;
            _stateCodeCtrl.text = newCode ?? '';
          });

          if (newCode != null) {
            await _loadCities(newCode);
          }
        } else {
          debugPrint('❌ State not matched: $_stateCode');
        }
      }

      if (_cityCode != null && _cities.isNotEmpty) {
        debugPrint('🔍 Matching city: $_cityCode');

        final matched = _cities.firstWhere((c) {
          final code = (c as dynamic).code?.toString().toLowerCase();
          final name = (c as dynamic).name?.toString().toLowerCase();
          final search = _cityCode?.toLowerCase();
          return code == search ||
              name == search ||
              name?.contains(search ?? '') == true;
        }, orElse: () => null);

        if (matched != null && mounted) {
          final newCode = (matched as dynamic).code?.toString();
          debugPrint('✅ City matched: $newCode');

          setState(() {
            _cityCode = newCode;
            _cityCodeCtrl.text = newCode ?? '';
          });
        } else {
          debugPrint('❌ City not matched: $_cityCode');
        }
      }
    });
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

  // ===== Loaders =====
  Future<void> _loadCountries() async {
    setState(() => _loadingGeo = true);
    try {
      final repo = ref.read(locationsRepositoryProvider);
      _countries = await repo.getCountries();
      // Validate countryCode against loaded countries
      if (_countryCode != null &&
          !_countries.any((c) => (c as dynamic).code == _countryCode)) {
        _countryCode = null;
        _countryCodeCtrl.text = '';
      }
    } finally {
      if (mounted) setState(() => _loadingGeo = false);
    }
  }

  Future<void> _loadStates(String countryCode) async {
    setState(() => _loadingGeo = true);
    try {
      final repo = ref.read(locationsRepositoryProvider);
      _states = await repo.getStates(countryCode);
      // Validate stateCode against loaded states
      if (_stateCode != null &&
          !_states.any((s) => (s as dynamic).code == _stateCode)) {
        _stateCode = null;
        _stateCodeCtrl.text = '';
      }
      // Reset city when state changes
      _cities = [];
      _cityCode = null;
      _cityCodeCtrl.text = '';
    } finally {
      if (mounted) setState(() => _loadingGeo = false);
    }
  }

  Future<void> _loadCities(String stateCode) async {
    setState(() => _loadingGeo = true);
    try {
      final repo = ref.read(locationsRepositoryProvider);
      _cities = await repo.getCities(stateCode);
      // Validate cityCode against loaded cities
      if (_cityCode != null &&
          !_cities.any((c) => (c as dynamic).code == _cityCode)) {
        _cityCode = null;
        _cityCodeCtrl.text = '';
      }
    } finally {
      if (mounted) setState(() => _loadingGeo = false);
    }
  }

  // ===== Save =====
  Future<void> _saveContact() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final form = ContactFormData(
        name: _nameCtrl.text.trim(),
        jobTitle: _jobCtrl.text.trim().isEmpty ? null : _jobCtrl.text.trim(),
        company: _companyCtrl.text.trim().isEmpty
            ? null
            : _companyCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        addressDetail: _addressDetailCtrl.text.trim().isEmpty
            ? null
            : _addressDetailCtrl.text.trim(),
        cityCode: _cityCode?.isEmpty == true
            ? null
            : _cityCode ??
                  (_cityCodeCtrl.text.isEmpty ? null : _cityCodeCtrl.text),
        stateCode: _stateCode?.isEmpty == true
            ? null
            : _stateCode ??
                  (_stateCodeCtrl.text.isEmpty ? null : _stateCodeCtrl.text),
        countryCode: _countryCode?.isEmpty == true
            ? null
            : _countryCode ??
                  (_countryCodeCtrl.text.isEmpty
                      ? null
                      : _countryCodeCtrl.text),
      );
      final contact = await repo.createContactFromForm(form);
      if (mounted) Navigator.pop(context, contact);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===== UI =====
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
                    const SizedBox(height: 8),
                    _countryDropdown(),
                    const SizedBox(height: 12),
                    _stateDropdown(),
                    const SizedBox(height: 12),
                    _cityDropdown(),

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

                    if (_loadingGeo) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ],
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
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
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
            ),
          ],
        ),
      ),
    );
  }

  // ===== Widgets nhỏ =====
  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _countryDropdown() {
    return DropdownButtonFormField<String>(
      value: (_countryCode == null || _countryCode!.isEmpty)
          ? null
          : _countryCode,
      decoration: _dropdownDecoration('Country'),
      isExpanded: true,
      items: _countries
          .map(
            (country) => DropdownMenuItem(
              value: (country as dynamic).code as String?,
              child: Text(
                '${(country as dynamic).name} (${(country as dynamic).code})',
              ),
            ),
          )
          .toList(),
      onChanged: (val) async {
        setState(() {
          _countryCode = val;
          _countryCodeCtrl.text = val ?? '';
          _stateCode = null;
          _stateCodeCtrl.text = '';
          _cityCode = null;
          _cityCodeCtrl.text = '';
          _states = [];
          _cities = [];
        });
        if (val != null && val.isNotEmpty) {
          await _loadStates(val);
        }
      },
    );
  }

  Widget _stateDropdown() {
    return DropdownButtonFormField<String>(
      value: (_stateCode == null || _stateCode!.isEmpty) ? null : _stateCode,
      decoration: _dropdownDecoration('State'),
      isExpanded: true,
      items: _states
          .map(
            (state) => DropdownMenuItem(
              value: (state as dynamic).code as String?,
              child: Text(
                '${(state as dynamic).name} (${(state as dynamic).code})',
              ),
            ),
          )
          .toList(),
      onChanged: (val) async {
        setState(() {
          _stateCode = val;
          _stateCodeCtrl.text = val ?? '';
          _cityCode = null;
          _cityCodeCtrl.text = '';
          _cities = [];
        });
        if (val != null && val.isNotEmpty) {
          await _loadCities(val);
        }
      },
    );
  }

  Widget _cityDropdown() {
    return DropdownButtonFormField<String>(
      value: (_cityCode == null || _cityCode!.isEmpty) ? null : _cityCode,
      decoration: _dropdownDecoration('City'),
      isExpanded: true,
      items: _cities
          .map(
            (city) => DropdownMenuItem(
              value: (city as dynamic).code as String?,
              child: Text(
                '${(city as dynamic).name} (${(city as dynamic).code})',
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        setState(() {
          _cityCode = val;
          _cityCodeCtrl.text = val ?? '';
        });
      },
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
