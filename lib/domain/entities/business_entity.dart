import 'package:equatable/equatable.dart';

class BusinessEntity extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessEntity({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.logoUrl,
    this.address,
    this.phone,
    this.email,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        description,
        logoUrl,
        address,
        phone,
        email,
        isActive,
        createdAt,
        updatedAt,
      ];
}

