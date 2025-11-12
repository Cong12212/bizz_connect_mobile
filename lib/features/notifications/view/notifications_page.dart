import 'dart:async';
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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize the controller to setup listeners
    Future.microtask(() {
      // This ensures the controller is created and listeners are setup
      ref.read(notificationsControllerProvider.notifier);
      // Then load data
      ref.read(notificationsControllerProvider.notifier).load();
    });

    // Auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(notificationsControllerProvider.notifier).loadSilent();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationsControllerProvider.notifier).loadSilent();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = ref.watch(notificationsControllerProvider);
    final c = ref.read(notificationsControllerProvider.notifier);

    final unreadCount = s.items.where((n) => n.status == 'unread').length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: s.loading ? null : c.load,
            icon: s.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(notificationsControllerProvider.notifier).load();
              },
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 8),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: s.items.length,
                itemBuilder: (_, i) {
                  final n = s.items[i];
                  final unread = n.status == 'unread';

                  return InkWell(
                    onTap: () => _onTapNotification(n),
                    child: Container(
                      color: unread ? const Color(0xFFEFF6FF) : Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar with badge
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE5E7EB),
                                child: _getIcon(n.type),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _getBadgeIcon(n.type),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and body combined
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: n.title,
                                        style: TextStyle(
                                          fontWeight: unread
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      if ((n.body ?? '').isNotEmpty)
                                        TextSpan(
                                          text: ' ${n.body}',
                                          style: TextStyle(
                                            fontWeight: unread
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                    ],
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Time
                                Text(
                                  _formatWhen(n),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Unread indicator & actions
                          Column(
                            children: [
                              if (unread)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(width: 10, height: 10),
                              const SizedBox(height: 8),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.more_horiz,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getIcon(String type) {
    if (type.contains('contact')) {
      return const Icon(Icons.person, color: Color(0xFF3B82F6));
    } else if (type.contains('reminder')) {
      return const Icon(Icons.notifications, color: Color(0xFFF59E0B));
    }
    return const Icon(Icons.info, color: Color(0xFF64748B));
  }

  Widget _getBadgeIcon(String type) {
    Color badgeColor;
    IconData badgeIcon;

    if (type.contains('contact')) {
      badgeColor = const Color(0xFF3B82F6);
      badgeIcon = Icons.person_add;
    } else if (type.contains('reminder')) {
      badgeColor = const Color(0xFFF59E0B);
      badgeIcon = Icons.access_time;
    } else {
      badgeColor = const Color(0xFF10B981);
      badgeIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
      child: Icon(badgeIcon, size: 10, color: Colors.white),
    );
  }

  void _onTapNotification(AppNotification n) {
    // Mark as read when tapped
    if (n.status == 'unread') {
      ref.read(notificationsControllerProvider.notifier).markRead(n.id);
    }

    // Navigate based on notification type
    if (n.contactId != null) {
      // Navigate to contacts page with query param to auto-open modal
      context.go('/contacts?openContactId=${n.contactId}');
    } else if (n.reminderId != null) {
      context.go('/reminders');
    } else if (n.type.startsWith('contact')) {
      context.go('/contacts');
    } else if (n.type.startsWith('reminder')) {
      context.go('/reminders');
    }
  }

  String _formatWhen(AppNotification n) {
    final d = n.scheduledAt ?? n.createdAt;
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    final dd = d.toLocal();
    return '${dd.day}/${dd.month}/${dd.year}';
  }

  String _targetPath(AppNotification n) {
    if (n.reminderId != null) return '/reminders?rid=${n.reminderId}';
    if (n.contactId != null) return '/contacts/${n.contactId}';
    if (n.type.startsWith('contact')) return '/contacts';
    if (n.type.startsWith('reminder')) return '/reminders';
    return '/';
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF0369A1) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
