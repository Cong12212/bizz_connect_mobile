class AppNotification {
  final int id;
  final int ownerUserId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  final int? contactId;
  final int? reminderId;
  final String status; // 'unread' | 'read' | 'done' | 'archived'
  final DateTime? scheduledAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.ownerUserId,
    required this.type,
    required this.title,
    this.body,
    this.data,
    this.contactId,
    this.reminderId,
    required this.status,
    this.scheduledAt,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as int,
    ownerUserId: j['owner_user_id'] as int,
    type: j['type'] as String,
    title: j['title'] as String,
    body: j['body'] as String?,
    data: j['data'] == null
        ? null
        : Map<String, dynamic>.from(j['data'] as Map),
    contactId: j['contact_id'] as int?,
    reminderId: j['reminder_id'] as int?,
    status: j['status'] as String,
    scheduledAt: j['scheduled_at'] == null
        ? null
        : DateTime.tryParse(j['scheduled_at'] as String),
    readAt: j['read_at'] == null
        ? null
        : DateTime.tryParse(j['read_at'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );
}

enum NotificationScope { all, unread, upcoming, past }

extension NotificationScopeX on NotificationScope {
  String get key => switch (this) {
    NotificationScope.all => 'all',
    NotificationScope.unread => 'unread',
    NotificationScope.upcoming => 'upcoming',
    NotificationScope.past => 'past',
  };
}
