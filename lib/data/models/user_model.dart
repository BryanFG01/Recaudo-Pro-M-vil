import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.businessId,
    required super.email,
    super.name,
    super.avatarUrl,
    super.employeeCode,
    super.phone,
    super.number,
    super.role,
    super.commissionPercentage,
    super.isActive,
  });

  /// Parsea is_active desde la API: bool, string "true"/"false", 0/1. Si falta, false (no permitir login).
  static bool _parseIsActive(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return false;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      email: (json['email'] as String?) ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      employeeCode: json['employee_code'] as String?,
      phone: json['phone'] as String?,
      number: json['number'] as String?,
      role: json['role'] as String? ?? 'cobrador',
      commissionPercentage: (json['commission_percentage'] as num?)?.toDouble() ?? 0,
      isActive: _parseIsActive(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'employee_code': employeeCode,
      'phone': phone,
      'number': number,
      'role': role,
      'commission_percentage': commissionPercentage,
      'is_active': isActive,
    };
  }
}

