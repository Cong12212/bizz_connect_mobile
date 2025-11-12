import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Tags
import '../../tags/data/tags_repository.dart';

// Contacts
import '../controller/contacts_list_controller.dart';
import '../data/models.dart';
import '../data/contacts_repository.dart';
import '../data/location_repository.dart';

// Widgets
import '../widgets/contact_avatar.dart';
import '../widgets/contact_action_icon.dart';
import '../widgets/select_tags_sheet.dart';

import '../../reminders/view/create_reminder_dialog.dart';

enum _Mode { view, edit, create }

class ContactDetailModal extends ConsumerStatefulWidget {
  const ContactDetailModal._({
    this.initialContact,
    required this.mode,
    super.key,
  });

  const ContactDetailModal.initialView({required Contact contact, Key? key})
    : this._(initialContact: contact, mode: _Mode.view, key: key);

  const ContactDetailModal.initialCreate({Key? key})
    : this._(initialContact: null, mode: _Mode.create, key: key);

  final Contact? initialContact;
  final _Mode mode;

  @override
  ConsumerState<ContactDetailModal> createState() => _ContactDetailModalState();
}

class _ContactDetailModalState extends ConsumerState<ContactDetailModal> {
  late _Mode _mode;
  Contact? _contact;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _job = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _addressDetail = TextEditingController();
  final _notes = TextEditingController();
  final _linkedin = TextEditingController();
  final _website = TextEditingController();

  // Dropdown data and selections
  List<GeoItem> _countries = [];
  List<GeoItem> _states = [];
  List<GeoItem> _cities = [];
  String? _countryCode;
  String? _stateCode;
  String? _cityCode;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _contact = widget.initialContact;
    _fillFromContact(widget.initialContact);

    _countryCode = widget.initialContact?.address?.country?.code;
    _stateCode = widget.initialContact?.address?.state?.code;
    _cityCode = widget.initialContact?.address?.city?.code;

    _loadCountries().then((_) async {
      if (_countryCode != null && _countryCode!.isNotEmpty) {
        await _loadStates(_countryCode!);
      }
      if (_stateCode != null && _stateCode!.isNotEmpty) {
        await _loadCities(_stateCode!);
      }
    });
  }

  void _fillFromContact(Contact? c) {
    if (c == null) return;
    _name.text = c.name;
    _job.text = c.jobTitle ?? '';
    _company.text = c.company ?? '';
    _email.text = c.email ?? '';
    _phone.text = c.phone ?? '';
    _addressDetail.text = c.address?.addressDetail ?? c.addressTextLegacy ?? '';
    _notes.text = c.notes ?? '';
    _linkedin.text = c.linkedinUrl ?? '';
    _website.text = c.websiteUrl ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _job.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _addressDetail.dispose();
    _notes.dispose();
    _linkedin.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final form = ContactFormData(
        name: _name.text.trim(),
        jobTitle: _job.text.trim().isEmpty ? null : _job.text.trim(),
        company: _company.text.trim().isEmpty ? null : _company.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        addressDetail: _addressDetail.text.trim().isEmpty
            ? null
            : _addressDetail.text.trim(),
        countryCode: (_countryCode ?? '').trim().isEmpty
            ? null
            : _countryCode!.trim(),
        stateCode: (_stateCode ?? '').trim().isEmpty
            ? null
            : _stateCode!.trim(),
        cityCode: (_cityCode ?? '').trim().isEmpty ? null : _cityCode!.trim(),
      );

      Contact result;
      if (_mode == _Mode.create) {
        result = await repo.createContactFromForm(form);
      } else {
        result = await repo.updateContactFromForm(_contact!.id, form);
      }
      setState(() => _contact = result);
      if (mounted) Navigator.pop<Contact?>(context, result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addReminder() async {
    final c = _contact;
    if (c == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => CreateReminderDialog(defaultContactId: c.id),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder created')));
    }
  }

  void _manageReminders() {
    final c = _contact;
    if (c == null) return;

    Navigator.pop(context, _contact);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/reminders');
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        title: const Text(
          'Delete Contact',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this contact? This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final repo = ref.read(contactsRepositoryProvider);
      await repo.deleteContact(widget.initialContact!.id);
      if (mounted) Navigator.pop<Contact?>(context, null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // ---------- GEO LOADERS ----------
  Future<void> _loadCountries() async {
    final repo = ref.read(locationsRepositoryProvider);
    final list = await repo.getCountries();
    setState(() => _countries = list);
  }

  Future<void> _loadStates(String countryCode) async {
    final repo = ref.read(locationsRepositoryProvider);
    final list = await repo.getStates(countryCode);
    setState(() => _states = list);
  }

  Future<void> _loadCities(String stateCode) async {
    final repo = ref.read(locationsRepositoryProvider);
    final list = await repo.getCities(stateCode);
    setState(() => _cities = list);
  }

  String _formatAddress(Contact c) {
    final parts = <String>[];
    final detail = c.address?.addressDetail;
    final city = c.address?.city?.name;
    final state = c.address?.state?.name;
    final country = c.address?.country?.name;

    if ((detail ?? '').trim().isNotEmpty) parts.add(detail!.trim());
    if ((city ?? '').trim().isNotEmpty) parts.add(city!.trim());
    if ((state ?? '').trim().isNotEmpty) parts.add(state!.trim());
    if ((country ?? '').trim().isNotEmpty) parts.add(country!.trim());

    if (parts.isNotEmpty) return parts.join(', ');
    return (c.addressTextLegacy ?? '').trim();
  }

  // ---------- TAGS ----------
  Future<void> _detachTagQuick(int tagId) async {
    final c = _contact;
    if (c == null) return;

    try {
      final repo = ref.read(contactsRepositoryProvider);
      await repo.detachTag(c.id, tagId);

      final fresh = await repo.getContact(c.id);
      if (!mounted) return;
      setState(() => _contact = fresh);

      ref.read(contactsListControllerProvider.notifier).refreshContact(fresh);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _openSelectTags() async {
    final c = _contact;
    if (c == null) return;

    final result = await showModalBottomSheet<TagSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectTagsSheet(
        contactId: c.id,
        initialIds: (c.tags ?? []).map((t) => t.id).toList(),
      ),
    );

    if (!mounted || result == null) return;

    if (result == TagSheetResult.manage) {
      GoRouter.of(context).push('/contacts/tags');
      return;
    }

    if (result == TagSheetResult.updated) {
      final repo = ref.read(contactsRepositoryProvider);
      final fresh = await repo.getContact(c.id);
      setState(() => _contact = fresh);
      ref.read(contactsListControllerProvider.notifier).refreshContact(fresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _mode == _Mode.edit || _mode == _Mode.create;
    final title = switch (_mode) {
      _Mode.create => 'New contact',
      _Mode.edit => 'Edit contact',
      _Mode.view => 'Contact details',
    };

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // ===== Header =====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop<Contact?>(context, _contact),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),

            // ===== Body scrollable =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: isEditing ? _buildForm() : _buildView(),
              ),
            ),

            // ===== Footer =====
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: isEditing
                  ? Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
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
                                  _mode == _Mode.create ? 'Next' : 'Save',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _delete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => setState(() => _mode = _Mode.edit),
                            child: const Text('Edit'),
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

  // ===== Form helpers =====
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            label: 'First Name',
            controller: _name,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'First name is required';
              }
              final firstChar = value.trim()[0];
              if (!RegExp(r'^[a-zA-Z0-9]').hasMatch(firstChar)) {
                return 'Name must start with a letter or number';
              }
              return null;
            },
          ),
          _buildTextField(
            label: 'Job Title',
            controller: _job,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Job title is required';
              }
              return null;
            },
          ),
          _buildTextField(label: 'Company', controller: _company),
          _buildTextField(
            label: 'Email Address',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email,
          ),
          _buildTextField(
            label: 'Phone Number',
            controller: _phone,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone,
          ),
          _buildTextField(label: 'Address Detail', controller: _addressDetail),
          _buildDropdown(
            label: 'Country',
            value: _countryCode?.isEmpty == true ? null : _countryCode,
            items: _countries,
            onChanged: (val) async {
              setState(() {
                _countryCode = val;
                _stateCode = null;
                _cityCode = null;
                _states = [];
                _cities = [];
              });
              if (val != null && val.isNotEmpty) {
                await _loadStates(val);
              }
            },
          ),
          _buildDropdown(
            label: 'State',
            value: _stateCode?.isEmpty == true ? null : _stateCode,
            items: _states,
            onChanged: (val) async {
              setState(() {
                _stateCode = val;
                _cityCode = null;
                _cities = [];
              });
              if (val != null && val.isNotEmpty) {
                await _loadCities(val);
              }
            },
          ),
          _buildDropdown(
            label: 'City',
            value: _cityCode?.isEmpty == true ? null : _cityCode,
            items: _cities,
            onChanged: (val) {
              setState(() => _cityCode = val);
            },
          ),
          _buildTextField(label: 'Notes', controller: _notes, maxLines: 3),
          _buildTextField(
            label: 'LinkedIn URL',
            controller: _linkedin,
            keyboardType: TextInputType.url,
          ),
          _buildTextField(
            label: 'Website URL',
            controller: _website,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: const Color(0xFF9CA3AF))
                : null,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixIcon != null ? 12 : 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<GeoItem> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: 'Select $label',
            hintStyle: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e.code, child: Text(e.name)))
              .toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }

  Widget _countryDropdown() {
    return DropdownButtonFormField<String>(
      value: _countryCode?.isEmpty == true ? null : _countryCode,
      decoration: _dropdownDecoration('Country'),
      isExpanded: true,
      items: _countries
          .map(
            (e) => DropdownMenuItem(
              value: e.code,
              child: Text('${e.name} (${e.code})'),
            ),
          )
          .toList(),
      onChanged: (val) async {
        setState(() {
          _countryCode = val;
          _stateCode = null;
          _cityCode = null;
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
      value: _stateCode?.isEmpty == true ? null : _stateCode,
      decoration: _dropdownDecoration('State'),
      isExpanded: true,
      items: _states
          .map(
            (e) => DropdownMenuItem(
              value: e.code,
              child: Text('${e.name} (${e.code})'),
            ),
          )
          .toList(),
      onChanged: (val) async {
        setState(() {
          _stateCode = val;
          _cityCode = null;
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
      value: _cityCode?.isEmpty == true ? null : _cityCode,
      decoration: _dropdownDecoration('City'),
      isExpanded: true,
      items: _cities
          .map(
            (e) => DropdownMenuItem(
              value: e.code,
              child: Text('${e.name} (${e.code})'),
            ),
          )
          .toList(),
      onChanged: (val) {
        setState(() => _cityCode = val);
      },
    );
  }

  // ===== View =====
  Widget _buildView() {
    final c = _contact!;
    final chips = (c.tags ?? [])
        .map(
          (t) => InputChip(
            label: Text('#${t.name}', style: const TextStyle(fontSize: 11)),
            onDeleted: () => _detachTagQuick(t.id),
            visualDensity: VisualDensity.compact,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            backgroundColor: const Color(0xFFF8FAFC),
          ),
        )
        .toList();

    Widget row(String label, String? value) {
      final v = (value ?? '').trim();
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: v.isEmpty ? const SizedBox.shrink() : Text(v)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ContactAvatar(name: c.name, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((c.company ?? c.jobTitle) != null)
                    Text(
                      [
                        c.jobTitle,
                        c.company,
                      ].where((e) => (e ?? '').isNotEmpty).join(' · '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: chips.isEmpty
                        ? const [
                            Text(
                              'No tags',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ]
                        : chips,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ContactActionIcon(
                        icon: Icons.label_outline,
                        label: 'Tags',
                        onTap: _openSelectTags,
                      ),
                      ContactActionIcon(
                        icon: Icons.settings_outlined,
                        label: 'Manage tags',
                        onTap: () {
                          Navigator.pop(context, _contact);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.go('/tags');
                          });
                        },
                      ),
                      ContactActionIcon(
                        icon: Icons.add_alarm,
                        label: 'Add reminder',
                        onTap: _addReminder,
                      ),
                      ContactActionIcon(
                        icon: Icons.event_note,
                        label: 'Reminders',
                        onTap: _manageReminders,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        row('Job Title', c.jobTitle),
        row('Company', c.company),
        row('Email', c.email),
        row('Phone', c.phone),
        row('Address', _formatAddress(c)),
        row('Notes', c.notes),
        row('LinkedIn', c.linkedinUrl),
        row('Website', c.websiteUrl),
      ],
    );
  }
}
