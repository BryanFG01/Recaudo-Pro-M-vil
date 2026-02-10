import '../../domain/entities/collection_entity.dart';

class CollectionModel extends CollectionEntity {
  const CollectionModel({
    required super.id,
    required super.creditId,
    required super.clientId,
    required super.amount,
    required super.paymentDate,
    super.notes,
    required super.userId,
    super.paymentMethod,
    super.transactionReference,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: _str(json['id'], ''),
      creditId: _str(json['credit_id'], ''),
      clientId: _str(json['client_id'], ''),
      amount: _toDouble(json['amount'], 0),
      paymentDate: _parseDate(json['payment_date']) ?? DateTime.now(),
      notes: json['notes'] as String?,
      userId: _str(json['user_id'], ''),
      paymentMethod: json['payment_method'] as String?,
      transactionReference: json['transaction_reference'] as String?,
    );
  }

  static String _str(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  static double _toDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson({String? businessId}) {
    final json = {
      'id': id,
      'credit_id': creditId,
      'client_id': clientId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'user_id': userId,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference,
    };
    if (businessId != null) {
      json['business_id'] = businessId;
    }
    return json;
  }
}
