import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/entities/credit_entity.dart';
import '../../domain/entities/credit_summary_entity.dart';
import '../models/credit_model.dart';

abstract class CreditRemoteDataSource {
  Future<List<CreditEntity>> getCreditsByBusiness(String businessId);
  Future<CreditEntity?> getCreditById(String id);
  Future<CreditSummaryEntity?> getCreditSummaryById(String creditId);
  /// GET /api/credits/summary?business_id=&user_id= → lista de resúmenes; suma total_paid = total recaudo real.
  Future<List<CreditSummaryEntity>> getCreditsSummaryByUser(
      String businessId, String userId);
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
    String? cashSessionId,
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
  Future<CreditSummaryEntity?> getCreditSummaryById(String creditId) async {
    final url = ApiConfig.buildApiUrl('/api/credits/summary/$creditId');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(
          'Error al obtener resumen del crédito: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseCreditSummary(data);
  }

  static CreditSummaryEntity _parseCreditSummary(Map<String, dynamic> json) {
    double toDouble(dynamic v, double def) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return def;
    }

    int toInt(dynamic v, int def) {
      if (v == null) return def;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return def;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return CreditSummaryEntity(
      totalBalance: toDouble(json['total_balance'], 0),
      totalPaid: toDouble(json['total_paid'], 0),
      totalAmount: toDouble(json['total_amount'], 0),
      lastPaymentDate: parseDate(json['last_payment_date']),
      paidInstallments: toInt(json['paid_installments'], 0),
      creditStatus: json['credit_status'] as String?,
    );
  }

  @override
  Future<List<CreditSummaryEntity>> getCreditsSummaryByUser(
      String businessId, String userId) async {
    final url = ApiConfig.buildApiUrlWithQuery(
      '/api/credits/summary',
      {'business_id': businessId, 'user_id': userId},
    );
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          'Error al obtener resúmenes de créditos: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    final list = body is List<dynamic> ? body : <dynamic>[];
    return list
        .map((e) => _parseCreditSummary(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
    String? cashSessionId,
  }) async {
    if (businessId == null || businessCode == null || userNumber == null) {
      throw Exception(
          'Faltan business_id, business_code o user_number para crear crédito');
    }
    final url = ApiConfig.buildApiUrl('/api/credits');
    // Body según API: client_id, document_id, user_number, total_amount,
    // installment_amount, total_installments, next_due_date, business_id,
    // business_code, interest_rate (0–30), total_interest, end_date (opcional cash_session_id)
    final endDate = credit.createdAt
        .add(Duration(days: credit.totalInstallments))
        .toUtc()
        .toIso8601String();
    final body = <String, dynamic>{
      'client_id': credit.clientId,
      'document_id': documentId ?? '',
      'user_number': userNumber,
      'total_amount': credit.totalAmount,
      'installment_amount': credit.installmentAmount,
      'total_installments': credit.totalInstallments,
      'next_due_date': credit.nextDueDate?.toUtc().toIso8601String(),
      'business_id': businessId,
      'business_code': businessCode,
      'end_date': endDate,
    };
    if (credit.interestRate != null) {
      body['interest_rate'] = credit.interestRate;
    }
    if (credit.totalInterest != null) {
      body['total_interest'] = credit.totalInterest;
    }
    if (cashSessionId != null && cashSessionId.isNotEmpty) {
      body['cash_session_id'] = cashSessionId;
    }
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Error al crear crédito: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err is Map<String, dynamic>) {
          final msg = err['message'] ?? err['error'] ?? err['detail'];
          if (msg != null) {
            message = msg is String ? msg : msg.toString();
          } else if (response.body.isNotEmpty && response.body.length < 300) {
            message = '$message - ${response.body}';
          }
        }
      } catch (_) {
        if (response.body.isNotEmpty && response.body.length < 300) {
          message = '$message - ${response.body}';
        }
      }
      throw Exception(message);
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
