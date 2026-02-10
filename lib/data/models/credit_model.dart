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
    return CreditModel(
      id: _stringOrEmpty(json['id']),
      clientId: _stringOrEmpty(json['client_id']),
      totalAmount: _toDouble(json['total_amount'], 0),
      installmentAmount: _toDouble(json['installment_amount'], 0),
      totalInstallments: _toIntPreferred(
          json['total_installments'], json['total_installments_created']),
      paidInstallments: _toInt(json['paid_installments'], 0),
      overdueInstallments: _toInt(json['overdue_installments'], 0),
      totalBalance: _toDouble(json['total_balance'], 0),
      lastPaymentAmount: _toDouble(json['last_payment_amount'], 0),
      lastPaymentDate: _parseDateTime(json['last_payment_date']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      nextDueDate: _parseDateTime(json['next_due_date']),
      interestRate: _toDoubleOrNull(json['interest_rate']),
      totalInterest: _toDoubleOrNull(json['total_interest']),
      cashSessionId: _stringOrEmptyNullable(json['cash_session_id']),
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

