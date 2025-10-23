import 'package:bizz_connect_mobile/core/models/pagination.dart';

// lib/features/contacts/data/models.dart
class Tag {
  final int id;
  final String name;
  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> j) =>
      Tag(id: j['id'] as int, name: j['name'] as String);
}

class Contact {
  final int id;
  final String name;
  final String? jobTitle;
  final String? company;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final String? linkedinUrl;
  final String? websiteUrl;
  final String? source;
  final List<Tag>? tags;
  final String? createdAt;
  final String? updatedAt;

  Contact({
    required this.id,
    required this.name,
    this.jobTitle,
    this.company,
    this.email,
    this.phone,
    this.address,
    this.notes,
    this.linkedinUrl,
    this.websiteUrl,
    this.source,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
    id: j['id'] as int,
    name: j['name'] as String,
    jobTitle: j['job_title'] as String?,
    company: j['company'] as String?,
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    address: j['address'] as String?,
    notes: j['notes'] as String?,
    linkedinUrl: j['linkedin_url'] as String?,
    websiteUrl: j['website_url'] as String?,
    source: j['source'] as String?,
    tags: (j['tags'] as List?)
        ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: j['created_at'] as String?,
    updatedAt: j['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'job_title': jobTitle,
    'company': company,
    'email': email,
    'phone': phone,
    'address': address,
    'notes': notes,
    'linkedin_url': linkedinUrl,
    'website_url': websiteUrl,
    'source': source,
    'tags': tags?.map((e) => {'id': e.id, 'name': e.name}).toList(),
  };
}

// ⬅️ XÓA class Paginated<T> ở đây, dùng từ core/models/pagination.dart
