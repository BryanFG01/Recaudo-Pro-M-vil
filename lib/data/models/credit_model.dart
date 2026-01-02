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
  });

  factory CreditModel.fromJson(Map<String, dynamic> json) {
    return CreditModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      installmentAmount: (json['installment_amount'] as num).toDouble(),
      totalInstallments: json['total_installments'] as int,
      paidInstallments: json['paid_installments'] as int,
      overdueInstallments: json['overdue_installments'] as int,
      totalBalance: (json['total_balance'] as num).toDouble(),
      lastPaymentAmount: json['last_payment_amount'] != null
          ? (json['last_payment_amount'] as num).toDouble()
          : 0,
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson({String? businessId}) {
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
    if (businessId != null) {
      json['business_id'] = businessId;
    }
    return json;
  }
}

