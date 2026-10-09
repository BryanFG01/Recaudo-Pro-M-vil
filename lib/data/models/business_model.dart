import '../../domain/entities/business_entity.dart';

class BusinessModel extends BusinessEntity {
  const BusinessModel({
    required super.id,
    required super.name,
    required super.code,
    super.description,
    super.logoUrl,
    super.address,
    super.phone,
    super.email,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['created_at']) ?? DateTime.now();
    return BusinessModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: createdAt,
      // Un negocio que nunca se editó llega con updated_at = null
      updatedAt: _parseDate(json['updated_at']) ?? createdAt,
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
