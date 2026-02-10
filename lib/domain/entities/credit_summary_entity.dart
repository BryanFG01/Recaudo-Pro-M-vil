import 'package:equatable/equatable.dart';

/// Resumen del crédito desde GET /api/credits/summary/{id}.
/// Incluye total_balance, total_paid y total_amount (lo prestado) calculados desde el backend.
class CreditSummaryEntity extends Equatable {
  final double totalBalance;
  final double totalPaid;
  /// Monto total del crédito (lo que se presta). Viene en la API summary.
  final double totalAmount;
  final DateTime? lastPaymentDate;
  final int paidInstallments;
  final String? creditStatus;

  const CreditSummaryEntity({
    required this.totalBalance,
    required this.totalPaid,
    this.totalAmount = 0,
    this.lastPaymentDate,
    this.paidInstallments = 0,
    this.creditStatus,
  });

  @override
  List<Object?> get props =>
      [totalBalance, totalPaid, totalAmount, lastPaymentDate, paidInstallments, creditStatus];
}
