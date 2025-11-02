// settings/data/settings_models.dart
import 'dart:io';

/* =========================
 * Me Model
 * ========================= */
class Me {
  final int id;
  final String? name;
  final String? email;

  Me({required this.id, this.name, this.email});

  factory Me.fromJson(Map<String, dynamic> j) => Me(
    id: j['id'] as int,
    name: j['name'] as String?,
    email: j['email'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

/* =========================
 * Company Models
 * ========================= */
class Company {
  final int id;
  final String name;
  final String? domain;
  final String? industry;
  final String? description;
  final String? website;
  final String? email;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? logo;
  final String? createdAt;
  final String? updatedAt;

  Company({
    required this.id,
    required this.name,
    this.domain,
    this.industry,
    this.description,
    this.website,
    this.email,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.logo,
    this.createdAt,
    this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> j) => Company(
    id: j['id'] as int,
    name: j['name'] as String,
    domain: j['domain'] as String?,
    industry: j['industry'] as String?,
    description: j['description'] as String?,
    website: j['website'] as String?,
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    addressLine1: j['address_line1'] as String?,
    addressLine2: j['address_line2'] as String?,
    city: j['city'] as String?,
    state: j['state'] as String?,
    country: j['country'] as String?,
    postalCode: j['postal_code'] as String?,
    logo: j['logo'] as String?,
    createdAt: j['created_at']?.toString(),
    updatedAt: j['updated_at']?.toString(),
  );
}

class CompanyForm {
  String name = '';
  String? domain;
  String? industry;
  String? description;
  String? website;
  String? email;
  String? phone;
  String? addressLine1;
  String? addressLine2;
  String? city;
  String? state;
  String? country;
  String? postalCode;
  File? logoFile;

  Map<String, dynamic> toMap() => {
    'name': name,
    if (domain != null) 'domain': domain,
    if (industry != null) 'industry': industry,
    if (description != null) 'description': description,
    if (website != null) 'website': website,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (addressLine1 != null) 'address_line1': addressLine1,
    if (addressLine2 != null) 'address_line2': addressLine2,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (country != null) 'country': country,
    if (postalCode != null) 'postal_code': postalCode,
  };
}

/* =========================
 * Business Card Models
 * ========================= */
class BusinessCard {
  final int id;
  final int userId;
  final int? companyId;
  final String? slug;
  final String fullName;
  final String? jobTitle;
  final String? department;
  final String email;
  final String? phone;
  final String? mobile;
  final String? website;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? linkedin;
  final String? facebook;
  final String? twitter;
  final String? avatar;
  final String? notes;
  final bool isPublic;
  final int viewCount;
  final String? createdAt;
  final String? updatedAt;

  BusinessCard({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.companyId,
    this.slug,
    this.jobTitle,
    this.department,
    this.phone,
    this.mobile,
    this.website,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.linkedin,
    this.facebook,
    this.twitter,
    this.avatar,
    this.notes,
    this.isPublic = true,
    this.viewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessCard.fromJson(Map<String, dynamic> j) => BusinessCard(
    id: j['id'] as int,
    userId: j['user_id'] as int,
    companyId: j['company_id'] as int?,
    slug: j['slug'] as String?,
    fullName: j['full_name'] as String,
    jobTitle: j['job_title'] as String?,
    department: j['department'] as String?,
    email: j['email'] as String,
    phone: j['phone'] as String?,
    mobile: j['mobile'] as String?,
    website: j['website'] as String?,
    addressLine1: j['address_line1'] as String?,
    addressLine2: j['address_line2'] as String?,
    city: j['city'] as String?,
    state: j['state'] as String?,
    country: j['country'] as String?,
    postalCode: j['postal_code'] as String?,
    linkedin: j['linkedin'] as String?,
    facebook: j['facebook'] as String?,
    twitter: j['twitter'] as String?,
    avatar: j['avatar'] as String?,
    notes: j['notes'] as String?,
    isPublic: (j['is_public'] is bool)
        ? j['is_public'] as bool
        : (j['is_public']?.toString() == '1'),
    viewCount: (j['view_count'] ?? 0) as int,
    createdAt: j['created_at']?.toString(),
    updatedAt: j['updated_at']?.toString(),
  );
}

class BusinessCardForm {
  int? companyId;
  String fullName = '';
  String email = '';
  String? jobTitle;
  String? department;
  String? phone;
  String? mobile;
  String? website;
  String? addressLine1;
  String? addressLine2;
  String? city;
  String? state;
  String? country;
  String? postalCode;
  String? linkedin;
  String? facebook;
  String? twitter;
  String? notes;
  bool isPublic = true;
  File? avatarFile;

  Map<String, dynamic> toMap() => {
    if (companyId != null) 'company_id': companyId,
    'full_name': fullName,
    'email': email,
    if (jobTitle != null) 'job_title': jobTitle,
    if (department != null) 'department': department,
    if (phone != null) 'phone': phone,
    if (mobile != null) 'mobile': mobile,
    if (website != null) 'website': website,
    if (addressLine1 != null) 'address_line1': addressLine1,
    if (addressLine2 != null) 'address_line2': addressLine2,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (country != null) 'country': country,
    if (postalCode != null) 'postal_code': postalCode,
    if (linkedin != null) 'linkedin': linkedin,
    if (facebook != null) 'facebook': facebook,
    if (twitter != null) 'twitter': twitter,
    if (notes != null) 'notes': notes,
    'is_public': isPublic ? '1' : '0', // backend chấp nhận 1/0
  };
}
