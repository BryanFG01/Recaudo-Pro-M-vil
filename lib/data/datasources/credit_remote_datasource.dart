import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/entities/credit_entity.dart';
import '../models/credit_model.dart';

abstract class CreditRemoteDataSource {
  Future<List<CreditEntity>> getCreditsByBusiness(String businessId);
  Future<CreditEntity?> getCreditById(String id);
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
  });
  Future<CreditEntity> updateCredit(
    CreditEntity credit, {
    String? businessId,
  });
}

class CreditRemoteDataSourceImpl implements CreditRemoteDataSource {
  @override
  Future<List<CreditEntity>> getCreditsByBusiness(String businessId) async {
    final url = ApiConfig.buildApiUrlWithQuery(
        '/api/credits', {'business_id': businessId});
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener créditos: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CreditModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<CreditEntity?> getCreditById(String id) async {
    final url = ApiConfig.buildApiUrl('/api/credits/$id');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Error al obtener crédito: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CreditModel.fromJson(data);
  }

  @override
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
  }) async {
    if (businessId == null || businessCode == null || userNumber == null) {
      throw Exception(
          'Faltan business_id, business_code o user_number para crear crédito');
    }
    final url = ApiConfig.buildApiUrl('/api/credits');
    // Body según API: client_id, document_id, user_number, total_amount,
    // installment_amount, total_installments, paid_installments,
    // overdue_installments, total_balance, last_payment_*, next_due_date,
    // business_id, business_code, interest_rate (0–30), total_interest
    final body = <String, dynamic>{
      'client_id': credit.clientId,
      'document_id': documentId,
      'user_number': userNumber,
      'total_amount': credit.totalAmount,
      'installment_amount': credit.installmentAmount,
      'total_installments': credit.totalInstallments,
      'paid_installments': credit.paidInstallments,
      'overdue_installments': credit.overdueInstallments,
      'total_balance': credit.totalBalance,
      'last_payment_amount': credit.lastPaymentAmount,
      'last_payment_date': credit.lastPaymentDate?.toIso8601String(),
      'next_due_date': credit.nextDueDate?.toIso8601String(),
      'business_id': businessId,
      'business_code': businessCode,
    };
    if (credit.interestRate != null) {
      body['interest_rate'] = credit.interestRate;
    }
    if (credit.totalInterest != null) {
      body['total_interest'] = credit.totalInterest;
    }
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear crédito: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CreditModel.fromJson(data);
  }

  @override
  Future<CreditEntity> updateCredit(
    CreditEntity credit, {
    String? businessId,
  }) async {
    if (businessId == null || businessId.isEmpty) {
      throw Exception(
          'business_id es requerido para actualizar el crédito (PATCH /api/credits/{id})');
    }
    final url = ApiConfig.buildApiUrl('/api/credits/${credit.id}');
    // Body según API: saldo, cuotas pagadas, último pago, próxima fecha,
    // interest_rate, total_interest. Incluye business_id.
    final updateData = <String, dynamic>{
      'business_id': businessId,
      'paid_installments': credit.paidInstallments,
      'total_balance': credit.totalBalance,
      'last_payment_amount': credit.lastPaymentAmount,
      'overdue_installments': credit.overdueInstallments,
    };
    if (credit.lastPaymentDate != null) {
      updateData['last_payment_date'] =
          credit.lastPaymentDate!.toIso8601String();
    }
    if (credit.nextDueDate != null) {
      updateData['next_due_date'] = credit.nextDueDate!.toIso8601String();
    }
    if (credit.interestRate != null) {
      updateData['interest_rate'] = credit.interestRate;
    }
    if (credit.totalInterest != null) {
      updateData['total_interest'] = credit.totalInterest;
    }
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );
    if (response.statusCode != 200) {
      String message = 'Error al actualizar crédito: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err is Map<String, dynamic>) {
          final msg = err['message'] ?? err['error'] ?? err['detail'];
          if (msg != null) message = msg is String ? msg : msg.toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) message += '\n${response.body}';
      }
      throw Exception(message);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CreditModel.fromJson(data);
  }
}
