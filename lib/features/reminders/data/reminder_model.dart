import 'package:bizz_connect_mobile/core/models/pagination.dart';

/// ================= Enums & helpers =================

enum ReminderStatus { pending, done, skipped, cancelled }

enum ReminderChannel { app, email, calendar }

ReminderStatus _statusFromString(String s) =>
    ReminderStatus.values.firstWhere((e) => e.name == s);
String? _statusToString(ReminderStatus? s) => s?.name;

ReminderChannel? _channelFromString(String? s) =>
    s == null ? null : ReminderChannel.values.firstWhere((e) => e.name == s);
String? _channelToString(ReminderChannel? c) => c?.name;

DateTime? _dt(String? iso) => iso == null ? null : DateTime.tryParse(iso);
String? _iso(DateTime? dt) => dt?.toIso8601String();

/// ================= Models =================

class Reminder {
  final int id;
  final int? contactId; // primary contact (nullable)
  final int ownerUserId;
  final String title;
  final String? note;
  final DateTime? dueAt;
  final ReminderStatus status;
  final ReminderChannel? channel;
  final String? externalEventId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Reminder({
    required this.id,
    required this.contactId,
    required this.ownerUserId,
    required this.title,
    this.note,
    this.dueAt,
    required this.status,
    this.channel,
    this.externalEventId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
    id: j['id'] as int,
    contactId: j['contact_id'] as int?,
    ownerUserId: (j['owner_user_id'] ?? j['ownerUserId']) as int,
    title: j['title'] as String,
    note: j['note'] as String?,
    dueAt: _dt(j['due_at'] as String?),
    status: _statusFromString(j['status'] as String),
    channel: _channelFromString(j['channel'] as String?),
    externalEventId: j['external_event_id'] as String?,
    createdAt: _dt(j['created_at'] as String)!,
    updatedAt: _dt(j['updated_at'] as String)!,
    deletedAt: _dt(j['deleted_at'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'contact_id': contactId,
    'owner_user_id': ownerUserId,
    'title': title,
    'note': note,
    'due_at': _iso(dueAt),
    'status': status.name,
    'channel': _channelToString(channel),
    'external_event_id': externalEventId,
    'created_at': _iso(createdAt),
    'updated_at': _iso(updatedAt),
    'deleted_at': _iso(deletedAt),
  };
}

/// Edge (pivot) giữa Reminder và Contact
class ReminderEdge {
  final String edgeKey; // "reminderId:contactId"
  final int reminderId;
  final int contactId;
  final String title;
  final String? note;
  final DateTime? dueAt;
  final ReminderStatus status;
  final ReminderChannel? channel;
  final bool isPrimary;
  final String contactName;
  final String? contactCompany;

  ReminderEdge({
    required this.edgeKey,
    required this.reminderId,
    required this.contactId,
    required this.title,
    this.note,
    this.dueAt,
    required this.status,
    this.channel,
    required this.isPrimary,
    required this.contactName,
    this.contactCompany,
  });

  factory ReminderEdge.fromJson(Map<String, dynamic> j) => ReminderEdge(
    edgeKey: j['edge_key'] as String,
    reminderId: j['reminder_id'] as int,
    contactId: j['contact_id'] as int,
    title: j['title'] as String,
    note: j['note'] as String?,
    dueAt: _dt(j['due_at'] as String?),
    status: _statusFromString(j['status'] as String),
    channel: _channelFromString(j['channel'] as String?),
    isPrimary: (j['is_primary'] == 1) || (j['is_primary'] == true),
    contactName: j['contact_name'] as String,
    contactCompany: j['contact_company'] as String?,
  );
}

/// Input tạo mới
class ReminderCreateInput {
  final List<int>? contactIds;
  final int? contactId; // primary
  final String title;
  final String? note;
  final DateTime? dueAt;
  final ReminderStatus? status;
  final ReminderChannel? channel;
  final String? externalEventId;

  ReminderCreateInput({
    this.contactIds,
    this.contactId,
    required this.title,
    this.note,
    this.dueAt,
    this.status,
    this.channel,
    this.externalEventId,
  });

  Map<String, dynamic> toJson() => {
    if (contactIds != null) 'contact_ids': contactIds,
    if (contactId != null) 'contact_id': contactId,
    'title': title,
    'note': note,
    'due_at': _iso(dueAt),
    if (status != null) 'status': status!.name,
    if (channel != null) 'channel': channel!.name,
    'external_event_id': externalEventId,
  };
}

/// Input cập nhật
class ReminderUpdateInput {
  final List<int>? contactIds;
  final int? contactId;
  final String? title;
  final String? note;
  final DateTime? dueAt;
  final ReminderStatus? status;
  final ReminderChannel? channel;
  final String? externalEventId;

  ReminderUpdateInput({
    this.contactIds,
    this.contactId,
    this.title,
    this.note,
    this.dueAt,
    this.status,
    this.channel,
    this.externalEventId,
  });

  Map<String, dynamic> toJson() => {
    if (contactIds != null) 'contact_ids': contactIds,
    if (contactId != null) 'contact_id': contactId,
    if (title != null) 'title': title,
    if (note != null) 'note': note,
    // API của bạn phân biệt undefined vs null:
    if (dueAt != null) 'due_at': _iso(dueAt),
    if (status != null) 'status': status!.name,
    if (channel != null) 'channel': channel!.name,
    if (externalEventId != null) 'external_event_id': externalEventId,
  };
}
