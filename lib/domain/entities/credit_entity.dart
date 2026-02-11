import 'package:equatable/equatable.dart';

class CreditEntity extends Equatable {
  final String id;
  final String clientId;
  final double totalAmount;
  final double installmentAmount;
  final int totalInstallments;
  final int paidInstallments;
  final int overdueInstallments;
  final double totalBalance;
  final double lastPaymentAmount;
  final DateTime? lastPaymentDate;
  final DateTime createdAt;
  final DateTime? nextDueDate;
  /// Tasa de interés del préstamo (0–30 %).
  final double? interestRate;
  /// Monto total del interés (total_amount * interest_rate / 100).
  final double? totalInterest;
  /// Sesión de caja a la que pertenece el crédito (si aplica). Para calcular ventas por sesión.
  final String? cashSessionId;

  /// Total a pagar (principal + interés). Para mostrar "total del crédito" en UI.
  double get totalToPay => totalAmount + (totalInterest ?? 0);

  const CreditEntity({
    required this.id,
    required this.clientId,
    required this.totalAmount,
    required this.installmentAmount,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.overdueInstallments,
    required this.totalBalance,
    this.lastPaymentAmount = 0,
    this.lastPaymentDate,
    required this.createdAt,
    this.nextDueDate,
    this.interestRate,
    this.totalInterest,
    this.cashSessionId,
  });

  @override
  List<Object?> get props => [
        id,
        clientId,
        totalAmount,
        installmentAmount,
        totalInstallments,
        paidInstallments,
        overdueInstallments,
        totalBalance,
        lastPaymentAmount,
        lastPaymentDate,
        createdAt,
        nextDueDate,
        interestRate,
        totalInterest,
        cashSessionId,
      ];
}

