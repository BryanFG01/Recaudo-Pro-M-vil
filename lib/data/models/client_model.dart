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
      id: _str(json['id'], ''),
      name: _str(json['name'], ''),
      phone: _str(json['phone'], ''),
      documentId: json['document_id'] as String?,
      documentFileUrl: json['document_file_url'] as String?,
      address: json['address'] as String?,
      latitude: _toDoubleOrNull(json['latitude']),
      longitude: _toDoubleOrNull(json['longitude']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static String _str(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
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

