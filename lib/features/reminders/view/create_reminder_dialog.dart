import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminder_model.dart';
import '../controller/reminder_crud_controller.dart';

class CreateReminderDialog extends ConsumerStatefulWidget {
  const CreateReminderDialog({super.key, this.defaultContactId});
  final int? defaultContactId;

  @override
  ConsumerState<CreateReminderDialog> createState() =>
      _CreateReminderDialogState();
}

class _CreateReminderDialogState extends ConsumerState<CreateReminderDialog> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _dueAt;
  ReminderChannel? _channel;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(reminderCrudProvider).isLoading;

    return AlertDialog(
      title: const Text('Create reminder'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: _dueAt ?? DateTime.now(),
                      );
                      if (picked == null) return;
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      setState(() {
                        _dueAt = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          t?.hour ?? 0,
                          t?.minute ?? 0,
                        );
                      });
                    },
                    child: Text(
                      _dueAt == null
                          ? 'Pick due datetime'
                          : 'Due: ${_dueAt!.toLocal()}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<ReminderChannel>(
                  value: _channel,
                  hint: const Text('Channel'),
                  onChanged: (v) => setState(() => _channel = v),
                  items: ReminderChannel.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      )
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving
              ? null
              : () async {
                  final input = ReminderCreateInput(
                    contactId: widget.defaultContactId,
                    title: _titleCtrl.text.trim(),
                    note: _noteCtrl.text.trim().isEmpty
                        ? null
                        : _noteCtrl.text.trim(),
                    dueAt: _dueAt,
                    channel: _channel,
                  );
                  await ref.read(reminderCrudProvider.notifier).create(input);
                  if (context.mounted) Navigator.pop(context, true);
                },
          child: saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
