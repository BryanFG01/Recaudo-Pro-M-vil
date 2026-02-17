import 'package:equatable/equatable.dart';

/// Intento de pago (PAID o NOT_PAID). POST /api/payment-attempts y GET para pintar en cuotas atrasadas.
class PaymentAttemptEntity extends Equatable {
  final String? id;
  final String creditId;
  final String clientId;
  /// Solo "PAID" o "NOT_PAID" (mayúsculas).
  final String status;
  final String? userId;
  final String? businessId;
  final String? businessCode;
  final DateTime? attemptDate;
  final String? collectionId;
  final int accumulatedNoPaymentDays;
  final String? notes;

  const PaymentAttemptEntity({
    this.id,
    required this.creditId,
    required this.clientId,
    required this.status,
    this.userId,
    this.businessId,
    this.businessCode,
    this.attemptDate,
    this.collectionId,
    this.accumulatedNoPaymentDays = 0,
    this.notes,
  });

  bool get isNotPaid => status == 'NOT_PAID';
  bool get isPaid => status == 'PAID';

  @override
  List<Object?> get props => [
        id,
        creditId,
        clientId,
        status,
        userId,
        businessId,
        businessCode,
        attemptDate,
        collectionId,
        accumulatedNoPaymentDays,
        notes,
      ];
}
