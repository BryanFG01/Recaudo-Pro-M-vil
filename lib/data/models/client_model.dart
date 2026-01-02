import '../../domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.name,
    required super.phone,
    super.documentId,
    super.address,
    super.latitude,
    super.longitude,
    required super.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      documentId: json['document_id'] as String?,
      address: json['address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson({String? businessId}) {
    final json = {
      'id': id,
      'name': name,
      'phone': phone,
      'document_id': documentId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
    if (businessId != null) {
      json['business_id'] = businessId;
    }
    return json;
  }
}

