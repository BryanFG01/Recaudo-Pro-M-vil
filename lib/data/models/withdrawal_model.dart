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
    super.kind,
    super.isRejected,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: (json['id'] ?? json['_id'] ?? json['withdrawal_id'] ?? '').toString(),
      cashSessionId:
          (json['cash_session_id'] ?? json['cashSessionId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      amount: _num(json['amount']),
      reason: json['reason'] as String? ?? '',
      isApproved:
          json['is_approved'] as bool? ?? json['isApproved'] as bool? ?? false,
      // La API envía UTC: se pasa a la hora del teléfono para mostrarla (antes salía 5 h adelantada)
      createdAt: _localDate(json['created_at'] ?? json['createdAt']),
      kind: json['kind'] as String? ?? 'withdrawal',
      isRejected: json['is_rejected'] as bool? ?? false,
      approvedAt: _localDate(json['approved_at'] ?? json['approvedAt']),
    );
  }

  static DateTime? _localDate(dynamic v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
