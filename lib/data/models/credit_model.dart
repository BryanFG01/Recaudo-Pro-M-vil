import '../../domain/entities/credit_entity.dart';

class CreditModel extends CreditEntity {
  const CreditModel({
    required super.id,
    required super.clientId,
    required super.totalAmount,
    required super.installmentAmount,
    required super.totalInstallments,
    required super.paidInstallments,
    required super.overdueInstallments,
    required super.totalBalance,
    super.lastPaymentAmount,
    super.lastPaymentDate,
    required super.createdAt,
    super.nextDueDate,
    super.interestRate,
    super.totalInterest,
    super.cashSessionId,
  });

  factory CreditModel.fromJson(Map<String, dynamic> json) {
    final raw =
        (json['credit'] ?? json['data'] ?? json) as Map<String, dynamic>;
    return CreditModel(
      id: _stringOrEmpty(raw['id'] ?? raw['_id'] ?? raw['credit_id']),
      clientId: _stringOrEmpty(raw['client_id'] ??
          raw['clientId'] ??
          (raw['client'] is Map
              ? raw['client']['id'] ?? raw['client']['_id']
              : null)),
      totalAmount: _toDouble(raw['total_amount'] ?? raw['totalAmount'], 0),
      installmentAmount:
          _toDouble(raw['installment_amount'] ?? raw['installmentAmount'], 0),
      totalInstallments: _toIntPreferred(
          raw['total_installments'] ?? raw['totalInstallments'],
          raw['total_installments_created']),
      paidInstallments:
          _toInt(raw['paid_installments'] ?? raw['paidInstallments'], 0),
      overdueInstallments:
          _toInt(raw['overdue_installments'] ?? raw['overdueInstallments'], 0),
      totalBalance: _toDouble(raw['total_balance'] ?? raw['totalBalance'], 0),
      lastPaymentAmount:
          _toDouble(raw['last_payment_amount'] ?? raw['lastPaymentAmount'], 0),
      lastPaymentDate:
          _parseDateTime(raw['last_payment_date'] ?? raw['lastPaymentDate']),
      createdAt: _parseDateTime(raw['created_at'] ?? raw['createdAt']) ??
          DateTime.now(),
      nextDueDate: _parseDateTime(raw['next_due_date'] ?? raw['nextDueDate']),
      interestRate:
          _toDoubleOrNull(raw['interest_rate'] ?? raw['interestRate']),
      totalInterest:
          _toDoubleOrNull(raw['total_interest'] ?? raw['totalInterest']),
      cashSessionId: _stringOrEmptyNullable(
          raw['cash_session_id'] ?? raw['cashSessionId']),
    );
  }

  static String? _stringOrEmptyNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  static String _stringOrEmpty(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return null;
  }

  static int _toIntPreferred(dynamic primary, dynamic fallback) {
    final p = _toInt(primary, 0);
    if (p > 0) return p;
    return _toInt(fallback, 0);
  }

  static int _toInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return defaultValue;
  }

  static double _toDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  Map<String, dynamic> toJson({
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
  }) {
    final json = {
      'id': id,
      'client_id': clientId,
      'total_amount': totalAmount,
      'installment_amount': installmentAmount,
      'total_installments': totalInstallments,
      'paid_installments': paidInstallments,
      'overdue_installments': overdueInstallments,
      'total_balance': totalBalance,
      'last_payment_amount': lastPaymentAmount,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'next_due_date': nextDueDate?.toIso8601String(),
    };
    if (interestRate != null) json['interest_rate'] = interestRate;
    if (totalInterest != null) json['total_interest'] = totalInterest;
    if (businessId != null) json['business_id'] = businessId;
    if (businessCode != null) json['business_code'] = businessCode;
    if (userNumber != null) json['user_number'] = userNumber;
    if (documentId != null) json['document_id'] = documentId;
    return json;
  }
}
