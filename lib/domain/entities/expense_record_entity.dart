import 'package:equatable/equatable.dart';

/// Registro de gasto para listar en el reporte (como retiros).
class ExpenseRecordEntity extends Equatable {
  final String id;
  final double amount;
  final String reason;
  final String categoryId;
  final DateTime createdAt;
  final bool isApproved;

  const ExpenseRecordEntity({
    required this.id,
    required this.amount,
    required this.reason,
    required this.categoryId,
    required this.createdAt,
    this.isApproved = false,
  });

  @override
  List<Object?> get props => [id, amount, reason, categoryId, createdAt, isApproved];
}
