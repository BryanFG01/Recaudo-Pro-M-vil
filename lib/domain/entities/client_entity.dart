import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? documentId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const ClientEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.documentId,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    documentId,
    address,
    latitude,
    longitude,
    createdAt,
  ];
}
