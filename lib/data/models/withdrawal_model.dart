import '../../domain/entities/withdrawal_entity.dart';

class WithdrawalModel extends WithdrawalEntity {
  const WithdrawalModel({
    required super.id,
    required super.cashSessionId,
    required super.userId,
    required super.amount,
    required super.reason,
    required super.isApproved,
    super.createdAt,
    super.approvedAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'] as String,
      cashSessionId: (json['cash_session_id'] ?? json['cashSessionId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      amount: _num(json['amount']),
      reason: json['reason'] as String? ?? '',
      isApproved: json['is_approved'] as bool? ?? json['isApproved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : json['approvedAt'] != null
              ? DateTime.parse(json['approvedAt'] as String)
              : null,
    );
  }

  static double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
