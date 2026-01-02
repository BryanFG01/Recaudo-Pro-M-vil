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
    super.role,
    super.commissionPercentage,
    super.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      employeeCode: json['employee_code'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'cobrador',
      commissionPercentage: (json['commission_percentage'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
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
      'role': role,
      'commission_percentage': commissionPercentage,
      'is_active': isActive,
    };
  }
}

