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
          // Scope chips – horizontal scroll to prevent UI overflow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: NotificationScope.values.map((sc) {
                final selected = s.scope == sc;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(sc.key),
                    selected: selected,
                    onSelected: (_) => c.setScope(sc),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: s.loading
                ? const Center(child: CircularProgressIndicator())
                : s.items.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.separated(
                    key: const PageStorageKey('notifications_list'),
                    itemCount: s.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (_, i) {
                      final n = s.items[i];
                      final checked = s.selected.contains(n.id);
                      final unread = n.status == 'unread';

                      return Material(
                        color: unread ? const Color(0xFFF0F9FF) : Colors.white,
                        child: ListTile(
                          onTap: () => _openNotification(context, n),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          dense: true,
                          leading: Checkbox(
                            value: checked,
                            onChanged: (v) => c.toggleOne(n.id, v ?? false),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Title (flexible)
                              Expanded(
                                child: Text(
                                  n.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: unread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (unread)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: CircleAvatar(
                                    radius: 3,
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((n.body ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
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
                              const SizedBox(height: 6),
                              // Meta row: badge type + time (flexible, no overflow)
                              Row(
                                children: [
                                  _TypeBadge(text: n.type),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatWhen(n),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Trailing with width constraint to prevent overflow
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.end,
                              children: [
                                if (unread)
                                  IconButton(
                                    onPressed: () => c.markRead(n.id),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                    ),
                                    tooltip: 'Mark as read',
                                  ),
                                IconButton(
                                  onPressed: () =>
                                      _openNotification(context, n),
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                  tooltip: 'Open notification',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Footer actions
          // Footer actions (REPLACE)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              color: Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: allChecked ? true : (someChecked ? null : false),
                  tristate: true,
                  onChanged: (v) => c.toggleAll(pageIds, v == true),
                ),
                const SizedBox(width: 6),
                Text(
                  'Selected: ${s.selected.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),

                // ✅ Constrain button size to avoid w=Infinity
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 180, // enough for "Mark read" + icon
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: s.selected.isEmpty
                            ? null
                            : () => c.bulkRead(),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text(
                          'Mark read',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
