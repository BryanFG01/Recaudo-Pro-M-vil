import '../../domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.name,
    required super.phone,
    super.documentId,
    super.documentFileUrl,
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
      documentFileUrl: json['document_file_url'] as String?,
      address: json['address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson({
    String? businessId,
    String? businessCode,
    String? userId,
    String? userNumber,
  }) {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'document_id': documentId,
      'document_file_url': documentFileUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
    if (businessId != null) json['business_id'] = businessId;
    if (businessCode != null) json['business_code'] = businessCode;
    if (userId != null) json['user_id'] = userId;
    if (userNumber != null) json['user_number'] = userNumber;
    return json;
  }
}

