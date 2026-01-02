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
      ];
}

