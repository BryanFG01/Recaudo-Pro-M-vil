import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String businessId;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? employeeCode;
  final String? phone;
  /// Número de usuario (usado por el back para login y en clients/credits/collections).
  final String? number;
  final String role;
  final double commissionPercentage;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.businessId,
    required this.email,
    this.name,
    this.avatarUrl,
    this.employeeCode,
    this.phone,
    this.number,
    this.role = 'cobrador',
    this.commissionPercentage = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        email,
        name,
        avatarUrl,
        employeeCode,
        phone,
        number,
        role,
        commissionPercentage,
        isActive,
      ];
}

