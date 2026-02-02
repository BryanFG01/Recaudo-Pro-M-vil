import 'package:equatable/equatable.dart';

class CashSessionEntity extends Equatable {
  final String id;
  final double initialBalance;
  final double? currentBalance;
  final String? userId;
  final String? businessId;
  final DateTime? openedAt;
  final DateTime? closedAt;

  const CashSessionEntity({
    required this.id,
    required this.initialBalance,
    this.currentBalance,
    this.userId,
    this.businessId,
    this.openedAt,
    this.closedAt,
  });

  @override
  List<Object?> get props =>
      [id, initialBalance, currentBalance, userId, businessId, openedAt, closedAt];
}
