import 'package:equatable/equatable.dart';

class CollectionEntity extends Equatable {
  final String id;
  final String creditId;
  final String clientId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final String userId;
  final String? paymentMethod;
  final String? transactionReference;

  const CollectionEntity({
    required this.id,
    required this.creditId,
    required this.clientId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    required this.userId,
    this.paymentMethod,
    this.transactionReference,
  });

  @override
  List<Object?> get props => [
        id,
        creditId,
        clientId,
        amount,
        paymentDate,
        notes,
        userId,
        paymentMethod,
        transactionReference,
      ];
}
