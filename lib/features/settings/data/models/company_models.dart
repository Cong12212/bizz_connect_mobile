class Company {
  final int id;
  final String name;
  final String? taxCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final String? logo;
  final int? addressId;
  final CompanyAddress? address;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  Company({
    required this.id,
    required this.name,
    this.taxCode,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.logo,
    this.addressId,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      taxCode: json['tax_code']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      description: json['description']?.toString(),
      logo: json['logo']?.toString(),
      addressId: json['address_id'] as int?,
      address: json['address'] != null
          ? CompanyAddress.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
    );
  }
}

class CompanyAddress {
  final int id;
  final String? addressDetail;
  final RefItem? city;
  final RefItem? state;
  final RefItem? country;

  CompanyAddress({
    required this.id,
    this.addressDetail,
    this.city,
    this.state,
    this.country,
  });

  factory CompanyAddress.fromJson(Map<String, dynamic> json) {
    return CompanyAddress(
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

class CompanyFormData {
  final String name;
  final String? taxCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final String? addressDetail;
  final String? city;
  final String? state;
  final String? country;

  CompanyFormData({
    required this.name,
    this.taxCode,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.addressDetail,
    this.city,
    this.state,
    this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (taxCode != null && taxCode!.isNotEmpty) 'tax_code': taxCode,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (website != null && website!.isNotEmpty) 'website': website,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (addressDetail != null && addressDetail!.isNotEmpty)
        'address_detail': addressDetail,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (country != null && country!.isNotEmpty) 'country': country,
    };
  }
}
