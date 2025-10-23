import 'package:bizz_connect_mobile/core/models/pagination.dart';

class Tag {
  final int id;
  String name;
  final int contactsCount;

  Tag({required this.id, required this.name, this.contactsCount = 0});

  factory Tag.fromJson(Map<String, dynamic> j) => Tag(
    id: j['id'] as int,
    name: j['name'] as String,
    contactsCount: (j['contacts_count'] ?? 0) as int,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
