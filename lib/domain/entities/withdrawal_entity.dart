import 'package:equatable/equatable.dart';

class WithdrawalEntity extends Equatable {
  final String id;
  final String cashSessionId;
  final String userId;
  final double amount;
  final String reason;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  const WithdrawalEntity({
    required this.id,
    required this.cashSessionId,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.isApproved,
    this.createdAt,
    this.approvedAt,
  });

  @override
  List<Object?> get props =>
      [id, cashSessionId, userId, amount, reason, isApproved, createdAt, approvedAt];
}
