import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controller/notifications_controller.dart';
import '../data/notification_models.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});
  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationsControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = ref.watch(notificationsControllerProvider);
    final c = ref.read(notificationsControllerProvider.notifier);

    final pageIds = s.items.map((e) => e.id).toList();
    final allChecked =
        pageIds.isNotEmpty && pageIds.every((id) => s.selected.contains(id));
    final someChecked =
        pageIds.any((id) => s.selected.contains(id)) && !allChecked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: s.loading ? null : c.load,
            icon: s.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // scope filter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 8,
              children: NotificationScope.values.map((sc) {
                final selected = s.scope == sc;
                return ChoiceChip(
                  label: Text(sc.key),
                  selected: selected,
                  onSelected: (_) => c.setScope(sc),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // header row
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: allChecked ? true : (someChecked ? null : false),
                  tristate: true,
                  onChanged: (v) => c.toggleAll(pageIds, v == true),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notification',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(
                  width: 120,
                  child: Text('When', textAlign: TextAlign.right),
                ),
                const SizedBox(width: 12),
                const SizedBox(
                  width: 120,
                  child: Text('Actions', textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          Expanded(
            child: s.loading
                ? const Center(child: CircularProgressIndicator())
                : s.items.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.builder(
                    key: const PageStorageKey('notifications_list'),
                    itemCount: s.items.length,
                    itemBuilder: (_, i) {
                      final n = s.items[i];
                      final checked = s.selected.contains(n.id);
                      final unread = n.status == 'unread';
                      return InkWell(
                        onTap: () => _openNotification(context, n),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: (v) => c.toggleOne(n.id, v ?? false),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: unread
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (unread)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 6.0),
                                            child: CircleAvatar(
                                              radius: 3,
                                              backgroundColor: Colors.blue,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if ((n.body ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                        ),
                                        child: Text(
                                          n.body!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Text(
                                          n.type,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  _formatWhen(n),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (unread)
                                      OutlinedButton(
                                        onPressed: () => c.markRead(n.id),
                                        child: const Text(
                                          'Mark read',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    TextButton(
                                      onPressed: () =>
                                          _openNotification(context, n),
                                      child: const Text(
                                        'Open',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // footer actions
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              color: Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                Text('Selected: ${s.selected.length}'),
                const Spacer(),
                FilledButton(
                  onPressed: s.selected.isEmpty ? null : () => c.bulkRead(),
                  child: const Text('Mark read'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openNotification(BuildContext context, AppNotification n) {
    final path = _targetPath(n);
    context.push(path);
  }

  String _formatWhen(AppNotification n) {
    final d = n.scheduledAt ?? n.createdAt;
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final dd = d.toLocal();
    final mm = dd.month.toString().padLeft(2, '0');
    final da = dd.day.toString().padLeft(2, '0');
    return '$da/$mm/${dd.year}';
  }

  String _targetPath(AppNotification n) {
    if (n.reminderId != null) return '/reminders?rid=${n.reminderId}';
    if (n.contactId != null) return '/contacts/${n.contactId}';
    if (n.type.startsWith('contact')) return '/contacts';
    if (n.type.startsWith('reminder')) return '/reminders';
    return '/';
  }
}
