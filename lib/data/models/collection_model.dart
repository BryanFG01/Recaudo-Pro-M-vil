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
      id: json['id'] as String,
      creditId: json['credit_id'] as String,
      clientId: json['client_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      notes: json['notes'] as String?,
      userId: json['user_id'] as String,
      paymentMethod: json['payment_method'] as String?,
      transactionReference: json['transaction_reference'] as String?,
    );
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
