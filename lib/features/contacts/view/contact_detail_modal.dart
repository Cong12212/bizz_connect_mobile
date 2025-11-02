import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Tags
import '../../tags/data/tags_repository.dart';
import '../../tags/data/tag_models.dart' as tagm;

// Contacts
import '../controller/contacts_list_controller.dart';
import '../data/models.dart';
import '../data/contacts_repository.dart';
import '../data/location_repository.dart'; // Must define: GeoItem + locationsRepositoryProvider

import '../../reminders/view/create_reminder_dialog.dart';

enum _Mode { view, edit, create }

enum _TagSheetResult { updated, manage, closed }

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

    // Prefill code selections from contact
    _countryCode = widget.initialContact?.address?.country?.code;
    _stateCode = widget.initialContact?.address?.state?.code;
    _cityCode = widget.initialContact?.address?.city?.code;

    // Load geo lists in dependency chain
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
        // lấy code từ dropdown selections
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
  // ---------- END GEO LOADERS ----------

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

    final result = await showModalBottomSheet<_TagSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectTagsSheet(
        contactId: c.id,
        initialIds: (c.tags ?? []).map((t) => t.id).toList(),
      ),
    );

    if (!mounted || result == null) return;

    if (result == _TagSheetResult.manage) {
      GoRouter.of(context).push('/contacts/tags');
      return;
    }

    if (result == _TagSheetResult.updated) {
      final repo = ref.read(contactsRepositoryProvider);
      final fresh = await repo.getContact(c.id);
      setState(() => _contact = fresh);
      ref.read(contactsListControllerProvider.notifier).refreshContact(fresh);
    }
  }
  // ---------- END TAGS ----------

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

                    // Bottom actions khi view
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

        // Address detail
        f('Address detail', _addressDetail),

        // Country / State / City dropdowns
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
            _Avatar(name: c.name, size: 64),
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
                      _ActionIcon(
                        icon: Icons.label_outline,
                        label: 'Tags',
                        onTap: _openSelectTags,
                      ),
                      _ActionIcon(
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
                      _ActionIcon(
                        icon: Icons.add_alarm,
                        label: 'Add reminder',
                        onTap: _addReminder,
                      ),
                      _ActionIcon(
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 56});
  final String name;
  final double size;

  String get initials {
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((s) => s[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE2E8F0),
      ),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap, this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF475569)),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label!,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet: select, attach, detach tags; with "Manage" button
class _SelectTagsSheet extends ConsumerStatefulWidget {
  const _SelectTagsSheet({required this.contactId, required this.initialIds});
  final int contactId;
  final List<int> initialIds;

  @override
  ConsumerState<_SelectTagsSheet> createState() => _SelectTagsSheetState();
}

class _SelectTagsSheetState extends ConsumerState<_SelectTagsSheet> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selected = {};
  List<tagm.Tag> _available = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialIds);
    _load();
  }

  Future<void> _load({String q = ''}) async {
    setState(() => _loading = true);
    final repo = ref.read(tagsRepositoryProvider);
    final res = await repo.listTags(q: q, page: 1);
    setState(() {
      _available = res.data;
      _loading = false;
    });
  }

  Future<void> _apply() async {
    final contactsRepo = ref.read(contactsRepositoryProvider);

    final initial = widget.initialIds.toSet();
    final now = _selected.toSet();
    final toAdd = now.difference(initial).toList();
    final toRemove = initial.difference(now).toList();

    if (toAdd.isNotEmpty) {
      await contactsRepo.attachTags(widget.contactId, ids: toAdd);
    }
    for (final id in toRemove) {
      await contactsRepo.detachTag(widget.contactId, id);
    }
    if (mounted) {
      Navigator.pop<_TagSheetResult>(context, _TagSheetResult.updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _loading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: _available.length,
            itemBuilder: (_, i) {
              final t = _available[i];
              final checked = _selected.contains(t.id);
              return CheckboxListTile(
                value: checked,
                title: Text(t.name),
                subtitle: Text('${t.contactsCount} contacts'),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(t.id);
                    } else {
                      _selected.remove(t.id);
                    }
                  });
                },
              );
            },
          );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Select tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Manage'),
                      onPressed: () {
                        Navigator.pop<_TagSheetResult>(
                          context,
                          _TagSheetResult.manage,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search tags…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => _load(q: _searchCtrl.text),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (v) => _load(q: v),
                ),
              ),
              const SizedBox(height: 8),

              // List with limited height (avoid unbounded)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: list,
              ),

              const Divider(height: 1),
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop<_TagSheetResult>(
                          context,
                          _TagSheetResult.closed,
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
