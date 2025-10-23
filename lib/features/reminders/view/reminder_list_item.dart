import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminder_model.dart';
import '../controller/reminder_crud_controller.dart';

class ReminderListItem extends ConsumerWidget {
  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.onTap,
    this.selected = false,
    this.onSelectChanged,
  });

  final Reminder reminder;
  final VoidCallback onTap;
  final bool selected;
  final ValueChanged<bool?>? onSelectChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final isOverdue =
    //     reminder.dueAt != null &&
    //     reminder.status == ReminderStatus.pending &&
    //     reminder.dueAt!.isBefore(DateTime.now());

    return Card(
      child: ListTile(
        leading: Checkbox(value: selected, onChanged: onSelectChanged),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: reminder.status == ReminderStatus.done
                ? FontWeight.w400
                : FontWeight.w600,
            decoration: reminder.status == ReminderStatus.done
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Text(
          [
            if (reminder.dueAt != null) 'Due: ${reminder.dueAt!.toLocal()}',
            'Status: ${reminder.status.name}',
            if (reminder.channel != null) 'Channel: ${reminder.channel!.name}',
          ].join(' • '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // if (isOverdue) const Icon(Icons.warning_amber_outlined),
            IconButton(
              tooltip: 'Mark done',
              icon: const Icon(Icons.check_circle_outline),
              onPressed: reminder.status == ReminderStatus.done
                  ? null
                  : () => ref
                        .read(reminderCrudProvider.notifier)
                        .markDone(reminder.id),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(reminderCrudProvider.notifier).delete(reminder.id),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
