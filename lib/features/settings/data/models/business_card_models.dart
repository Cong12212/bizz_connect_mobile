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
  final String? linkedin;
  final String? facebook;
  final String? twitter;
  final String? avatar;
  final String? notes;
  final bool? isPublic;
  final int? viewCount;
  final String createdAt;
  final String updatedAt;
  final int? addressId;
  final BusinessCardAddress? address;
  final BusinessCardCompany? company;

  BusinessCard({
    required this.id,
    required this.userId,
    this.companyId,
    this.slug,
    required this.fullName,
    this.jobTitle,
    this.department,
    required this.email,
    this.phone,
    this.mobile,
    this.website,
    this.linkedin,
    this.facebook,
    this.twitter,
    this.avatar,
    this.notes,
    this.isPublic,
    this.viewCount,
    required this.createdAt,
    required this.updatedAt,
    this.addressId,
    this.address,
    this.company,
  });

  factory BusinessCard.fromJson(Map<String, dynamic> json) {
    return BusinessCard(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      companyId: json['company_id'] as int?,
      slug: json['slug']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      jobTitle: json['job_title']?.toString(),
      department: json['department']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      mobile: json['mobile']?.toString(),
      website: json['website']?.toString(),
      linkedin: json['linkedin']?.toString(),
      facebook: json['facebook']?.toString(),
      twitter: json['twitter']?.toString(),
      avatar: json['avatar']?.toString(),
      notes: json['notes']?.toString(),
      isPublic: json['is_public'] as bool?,
      viewCount: json['view_count'] as int?,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      addressId: json['address_id'] as int?,
      address: json['address'] != null
          ? BusinessCardAddress.fromJson(
              json['address'] as Map<String, dynamic>,
            )
          : null,
      company: json['company'] != null
          ? BusinessCardCompany.fromJson(
              json['company'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class BusinessCardAddress {
  final int id;
  final String? addressDetail;
  final RefItem? city;
  final RefItem? state;
  final RefItem? country;

  BusinessCardAddress({
    required this.id,
    this.addressDetail,
    this.city,
    this.state,
    this.country,
  });

  factory BusinessCardAddress.fromJson(Map<String, dynamic> json) {
    return BusinessCardAddress(
      id: json['id'] as int,
      addressDetail: json['address_detail']?.toString(),
      city: json['city'] != null
          ? RefItem.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      state: json['state'] != null
          ? RefItem.fromJson(json['state'] as Map<String, dynamic>)
          : null,
      country: json['country'] != null
          ? RefItem.fromJson(json['country'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BusinessCardCompany {
  final int id;
  final String name;
  final String? website;
  final String? logo;

  BusinessCardCompany({
    required this.id,
    required this.name,
    this.website,
    this.logo,
  });

  factory BusinessCardCompany.fromJson(Map<String, dynamic> json) {
    return BusinessCardCompany(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      website: json['website']?.toString(),
      logo: json['logo']?.toString(),
    );
  }
}

class RefItem {
  final int id;
  final String code;
  final String name;

  RefItem({required this.id, required this.code, required this.name});

  factory RefItem.fromJson(Map<String, dynamic> json) {
    return RefItem(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class BusinessCardFormData {
  final int? companyId;
  final String fullName;
  final String email;
  final String? jobTitle;
  final String? department;
  final String? phone;
  final String? mobile;
  final String? website;
  final String? linkedin;
  final String? facebook;
  final String? twitter;
  final String? notes;
  final bool? isPublic;
  final String? addressDetail;
  final String? city;
  final String? state;
  final String? country;

  BusinessCardFormData({
    this.companyId,
    required this.fullName,
    required this.email,
    this.jobTitle,
    this.department,
    this.phone,
    this.mobile,
    this.website,
    this.linkedin,
    this.facebook,
    this.twitter,
    this.notes,
    this.isPublic,
    this.addressDetail,
    this.city,
    this.state,
    this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      if (companyId != null) 'company_id': companyId,
      'full_name': fullName,
      'email': email,
      if (jobTitle != null && jobTitle!.isNotEmpty) 'job_title': jobTitle,
      if (department != null && department!.isNotEmpty)
        'department': department,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (mobile != null && mobile!.isNotEmpty) 'mobile': mobile,
      if (website != null && website!.isNotEmpty) 'website': website,
      if (linkedin != null && linkedin!.isNotEmpty) 'linkedin': linkedin,
      if (facebook != null && facebook!.isNotEmpty) 'facebook': facebook,
      if (twitter != null && twitter!.isNotEmpty) 'twitter': twitter,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isPublic != null) 'is_public': isPublic! ? 1 : 0,
      if (addressDetail != null && addressDetail!.isNotEmpty)
        'address_detail': addressDetail,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (country != null && country!.isNotEmpty) 'country': country,
    };
  }
}
