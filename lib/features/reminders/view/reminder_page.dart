import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminder_model.dart';
import '../controller/reminders_list_controller.dart';
import 'reminder_list_item.dart';
import 'create_reminder_dialog.dart';
import 'package:bizz_connect_mobile/core/models/pagination.dart';
import '../controller/reminder_crud_controller.dart';
import 'package:go_router/go_router.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});
  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage>
    with AutomaticKeepAliveClientMixin {
  final Set<int> _selectedIds = {};
  bool _initedByQuery = false;

  @override
  bool get wantKeepAlive => true; // giữ state trang khi rời/đi về

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initedByQuery) return;

    // Đọc query chỉ 1 lần (nếu có contactId thì filter theo contact)
    final location = GoRouterState.of(context).uri.toString();
    final uri = Uri.parse(location);
    final cidStr = uri.queryParameters['contactId'];
    if (cidStr != null) {
      final cid = int.tryParse(cidStr);
      if (cid != null) {
        final f = ref.read(reminderFiltersProvider);
        ref.read(reminderFiltersProvider.notifier).state = f.copyWith(
          contactId: cid,
          page: 1,
        );
        // refresh theo filter mới
        ref.read(remindersListProvider.notifier).refresh();
      }
    }
    _initedByQuery = true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // cần gọi khi dùng AutomaticKeepAliveClientMixin
    final listState = ref.watch(remindersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          PopupMenuButton<ReminderStatus?>(
            tooltip: 'Filter Status',
            onSelected: (s) =>
                ref.read(remindersListProvider.notifier).setStatus(s),
            itemBuilder: (_) => <PopupMenuEntry<ReminderStatus?>>[
              const PopupMenuItem(value: null, child: Text('All')),
              ...ReminderStatus.values.map(
                (s) => PopupMenuItem(value: s, child: Text(s.name)),
              ),
            ],
            icon: const Icon(Icons.filter_alt_outlined),
          ),
          IconButton(
            tooltip: 'New reminder',
            icon: const Icon(Icons.add),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => const CreateReminderDialog(),
              );
              if (ok == true) {
                // list sẽ tự refresh nếu cần qua controller
              }
            },
          ),
        ],
      ),
      body: listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (page) => _buildList(context, page),
      ),
      bottomNavigationBar: listState.maybeWhen(
        data: (page) => _Pager(
          page: page.currentPage,
          lastPage: page.lastPage,
          onChange: (p) => ref.read(remindersListProvider.notifier).goToPage(p),
        ),
        orElse: () => null,
      ),
      floatingActionButton: _selectedIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.delete_outline),
              label: Text('Delete (${_selectedIds.length})'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete selected reminders?'),
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
                if (confirm == true) {
                  await ref
                      .read(reminderCrudProvider.notifier)
                      .bulkDelete(_selectedIds.toList());
                  setState(() => _selectedIds.clear());
                }
              },
            ),
    );
  }

  Widget _buildList(BuildContext context, Paginated<Reminder> page) {
    if (page.data.isEmpty) {
      return const Center(child: Text('No reminders'));
    }
    return ListView.builder(
      key: const PageStorageKey('reminders_list'), // lưu vị trí scroll
      padding: const EdgeInsets.all(8),
      itemCount: page.data.length,
      itemBuilder: (_, i) {
        final r = page.data[i];
        final selected = _selectedIds.contains(r.id);
        return ReminderListItem(
          reminder: r,
          selected: selected,
          onSelectChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedIds.add(r.id);
              } else {
                _selectedIds.remove(r.id);
              }
            });
          },
          onTap: () {
            // mở bottom sheet xem chi tiết / thao tác nhanh
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => _ReminderDetailSheet(reminder: r),
            );
          },
        );
      },
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.lastPage,
    required this.onChange,
  });
  final int page;
  final int lastPage;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => onChange(page - 1) : null,
          ),
          Text('Page $page / $lastPage'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < lastPage ? () => onChange(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _ReminderDetailSheet extends ConsumerWidget {
  const _ReminderDetailSheet({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reminder.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: reminder.status == ReminderStatus.done
                    ? null
                    : () => ref
                          .read(reminderCrudProvider.notifier)
                          .markDone(reminder.id),
                icon: const Icon(Icons.check),
                label: const Text('Mark done'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(reminderCrudProvider.notifier)
                      .delete(reminder.id);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
