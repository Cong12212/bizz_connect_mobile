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
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
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

    final router = GoRouter.of(context);
    Navigator.pop(context, _contact);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.push('/contacts/reminders');
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.transparent,
        child: FractionallySizedBox(
          heightFactor: 0.95,
          widthFactor: 1,
          alignment: Alignment.bottomCenter,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Material(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Top bar
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop<Contact?>(context, _contact);
                            },
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isEditing)
                            SizedBox(
                              height: 36,
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  minimumSize: const Size(64, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save'),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: isEditing ? _buildForm() : _buildView(),
                      ),
                    ),

                    // Bottom actions
                    if (!isEditing && _contact != null)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _delete,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(
                                      color: Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () =>
                                      setState(() => _mode = _Mode.edit),
                                  child: const Text('Edit'),
                                ),
                              ),
                            ],
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

  // ===== Form helpers =====
  Widget _buildForm() {
    Widget f(String label, TextEditingController c, {TextInputType? type}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            keyboardType: type,
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
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        f('Name *', _name),
        f('Job Title', _job),
        f('Company', _company),
        f('Email', _email, type: TextInputType.emailAddress),
        f('Phone', _phone, type: TextInputType.phone),
        f('Address detail', _addressDetail),
        _countryDropdown(),
        const SizedBox(height: 12),
        _stateDropdown(),
        const SizedBox(height: 12),
        _cityDropdown(),
        const SizedBox(height: 12),
        f('Notes', _notes),
        f('LinkedIn URL', _linkedin, type: TextInputType.url),
        f('Website URL', _website, type: TextInputType.url),
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
                          final router = GoRouter.of(context);
                          Navigator.pop(context, _contact);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            router.push('/contacts/tags');
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
