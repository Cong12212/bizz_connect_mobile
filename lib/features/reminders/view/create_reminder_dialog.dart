import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminder_model.dart';
import '../controller/reminder_crud_controller.dart';
import '../../contacts/data/contacts_repository.dart';
import '../../contacts/data/models.dart';

class CreateReminderDialog extends ConsumerStatefulWidget {
  const CreateReminderDialog({this.defaultContactId, super.key});

  final int? defaultContactId;

  @override
  ConsumerState<CreateReminderDialog> createState() =>
      _CreateReminderDialogState();
}

class _CreateReminderDialogState extends ConsumerState<CreateReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading = false;

  // Contact selection
  List<Contact> _contacts = [];
  List<int> _selectedContactIds = [];
  bool _loadingContacts = false;

  @override
  void initState() {
    super.initState();
    if (widget.defaultContactId != null) {
      _selectedContactIds = [widget.defaultContactId!];
    }
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final result = await repo.listContacts(perPage: 100);
      if (mounted) {
        setState(() {
          _contacts = result.data;
          _loadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingContacts = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  Future<void> _selectContacts() async {
    final selected = await showModalBottomSheet<Set<int>?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ContactSelectionSheet(
        contacts: _contacts,
        initialSelected: Set.from(_selectedContactIds),
        isLoading: _loadingContacts,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedContactIds = selected.toList();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      DateTime? dueAt;
      if (_selectedDate != null && _selectedTime != null) {
        dueAt = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      final input = ReminderCreateInput(
        title: _titleController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        dueAt: dueAt,
        status: ReminderStatus.pending,
        contactIds: _selectedContactIds.isEmpty ? null : _selectedContactIds,
      );

      await ref.read(reminderCrudProvider.notifier).create(input);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _getContactsLabel() {
    if (_selectedContactIds.isEmpty) return 'No contacts selected';
    if (_selectedContactIds.length == 1) {
      final contact = _contacts.firstWhere(
        (c) => c.id == _selectedContactIds.first,
        orElse: () => Contact(
          id: 0,
          name: 'Unknown',
          email: null,
          phone: null,
          company: null,
          jobTitle: null,
          notes: null,
          linkedinUrl: null,
          websiteUrl: null,
          addressTextLegacy: null,
          address: null,
          tags: null,
        ),
      );
      return contact.name;
    }
    return '${_selectedContactIds.length} contacts selected';
  }

  @override
  Widget build(BuildContext context) {
    final hasDefaultContact = widget.defaultContactId != null;

    return AlertDialog(
      title: const Text('New Reminder'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                enabled: !_loading,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !_loading,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _selectDateTime,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDate == null
                      ? 'Select due date'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} ${_selectedTime?.format(context) ?? ''}',
                ),
              ),
              if (!hasDefaultContact) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _selectContacts,
                  icon: const Icon(Icons.people_outline),
                  label: Text(_getContactsLabel()),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

// Separate widget for contact selection
class _ContactSelectionSheet extends StatefulWidget {
  const _ContactSelectionSheet({
    required this.contacts,
    required this.initialSelected,
    required this.isLoading,
  });

  final List<Contact> contacts;
  final Set<int> initialSelected;
  final bool isLoading;

  @override
  State<_ContactSelectionSheet> createState() => _ContactSelectionSheetState();
}

class _ContactSelectionSheetState extends State<_ContactSelectionSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Select Contacts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_selected.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selected.length} selected',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // List
              Flexible(
                child: widget.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : widget.contacts.isEmpty
                    ? const Center(child: Text('No contacts available'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: widget.contacts.length,
                        itemBuilder: (context, index) {
                          final contact = widget.contacts[index];
                          final isSelected = _selected.contains(contact.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selected.add(contact.id);
                                } else {
                                  _selected.remove(contact.id);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              backgroundColor: const Color(0xFFE2E8F0),
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(contact.name),
                            subtitle: Text(
                              contact.email ??
                                  contact.phone ??
                                  contact.company ??
                                  '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
