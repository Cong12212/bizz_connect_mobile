// lib/features/contacts/data/models.dart
import 'package:bizz_connect_mobile/core/models/pagination.dart';

class Tag {
  final int id;
  final String name;
  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> j) =>
      Tag(id: j['id'] as int, name: j['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// Ref item đồng bộ với web (id/code/name)
class RefItem {
  final int id;
  final String code;
  final String name;

  RefItem({required this.id, required this.code, required this.name});

  factory RefItem.fromJson(Map<String, dynamic> j) => RefItem(
    id: j['id'] as int,
    code: (j['code'] ?? '') as String,
    name: (j['name'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name': name};
}

/// Address giống cấu trúc bên React
class Address {
  final int id;
  final String? addressDetail;
  final RefItem? city;
  final RefItem? state;
  final RefItem? country;

  Address({
    required this.id,
    this.addressDetail,
    this.city,
    this.state,
    this.country,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    id: j['id'] as int,
    addressDetail: j['address_detail'] as String?,
    city: j['city'] == null
        ? null
        : RefItem.fromJson(j['city'] as Map<String, dynamic>),
    state: j['state'] == null
        ? null
        : RefItem.fromJson(j['state'] as Map<String, dynamic>),
    country: j['country'] == null
        ? null
        : RefItem.fromJson(j['country'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'address_detail': addressDetail,
    'city': city?.toJson(),
    'state': state?.toJson(),
    'country': country?.toJson(),
  };
}

class Contact {
  final int id;
  final String name;

  // Thông tin chung (giữ nguyên)
  final String? jobTitle;
  final String? company;
  final String? email;
  final String? phone;

  /// ====== Address (đã đổi) ======
  /// BE trả về: address_id (int?) và address (object) như bên React
  final int? addressId; // address_id
  final Address?
  address; // address object (id, address_detail, city/state/country)

  // Phần này vẫn giữ để không vỡ UI cũ, nhưng KHÔNG khuyến khích dùng nữa.
  // Nếu trước đây bạn show `address` dạng String, có thể tạm map từ address.addressDetail.
  final String? addressTextLegacy;

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
    this.addressId,
    this.address,
    this.addressTextLegacy,
    this.notes,
    this.linkedinUrl,
    this.websiteUrl,
    this.source,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> j) {
    final addrObj = j['address'];
    final addressParsed = (addrObj is Map<String, dynamic>)
        ? Address.fromJson(addrObj)
        : null;

    return Contact(
      id: j['id'] as int,
      name: j['name'] as String,
      jobTitle: j['job_title'] as String?,
      company: j['company'] as String?,
      email: j['email'] as String?,
      phone: j['phone'] as String?,
      addressId: j['address_id'] as int?,
      address: addressParsed,
      // nếu API cũ còn trả 'address' là String, bắt lại an toàn:
      addressTextLegacy: j['address'] is String
          ? j['address'] as String?
          : null,
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
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'job_title': jobTitle,
      'company': company,
      'email': email,
      'phone': phone,

      // Gửi đúng định dạng BE:
      // - Nếu đã có addressId thì gửi 'address_id'
      // - Nếu muốn tạo/cập nhật address theo code (giống web), bạn có thể bổ sung payload form riêng (xem ghi chú bên dưới)
      'address_id': addressId,

      // Không khuyến khích gửi 'address' full object vào toJson của entity (tùy API).
      // Nếu cần submit form theo code như web, tạo lớp *ContactFormData* riêng.
      'notes': notes,
      'linkedin_url': linkedinUrl,
      'website_url': websiteUrl,
      'source': source,
      'tags': tags?.map((e) => {'id': e.id, 'name': e.name}).toList(),
    };
  }
}

class ContactFormData {
  final String name;
  final String? jobTitle;
  final String? company;
  final String? email;
  final String? phone;

  // Cách 1: có sẵn id
  final int? addressId;

  // Cách 2: gửi code để BE map
  final String? addressDetail;
  final String? cityCode;
  final String? stateCode;
  final String? countryCode;

  ContactFormData({
    required this.name,
    this.jobTitle,
    this.company,
    this.email,
    this.phone,
    this.addressId,
    this.addressDetail,
    this.cityCode,
    this.stateCode,
    this.countryCode,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'job_title': jobTitle,
    'company': company,
    'email': email,
    'phone': phone,
    if (addressId != null) 'address_id': addressId,
    if (addressDetail != null) 'address_detail': addressDetail,
    if (cityCode != null) 'city': cityCode,
    if (stateCode != null) 'state': stateCode,
    if (countryCode != null) 'country': countryCode,
  };
}
