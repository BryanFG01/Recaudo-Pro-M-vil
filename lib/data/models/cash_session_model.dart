import '../../domain/entities/cash_session_entity.dart';

class CashSessionModel extends CashSessionEntity {
  const CashSessionModel({
    required super.id,
    required super.initialBalance,
    super.currentBalance,
    super.userId,
    super.businessId,
    super.openedAt,
    super.closedAt,
  });

  factory CashSessionModel.fromJson(Map<String, dynamic> json) {
    return CashSessionModel(
      id: (json['id'] ?? json['cash_session_id'] ?? '').toString(),
      initialBalance: _num(json['initial_balance'] ?? json['initialBalance']),
      currentBalance: json['current_balance'] != null || json['currentBalance'] != null
          ? _num(json['current_balance'] ?? json['currentBalance'])
          : null,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      businessId: json['business_id'] as String? ?? json['businessId'] as String?,
      openedAt: json['opened_at'] != null
          ? DateTime.parse(json['opened_at'] as String)
          : json['openedAt'] != null
              ? DateTime.parse(json['openedAt'] as String)
              : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : json['closedAt'] != null
              ? DateTime.parse(json['closedAt'] as String)
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
