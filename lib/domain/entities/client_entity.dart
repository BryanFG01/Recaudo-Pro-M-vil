import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? documentId;
  /// URL del documento (ej: DNI, PDF) subido a storage.
  final String? documentFileUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const ClientEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.documentId,
    this.documentFileUrl,
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
    documentFileUrl,
    address,
    latitude,
    longitude,
    createdAt,
  ];
}
