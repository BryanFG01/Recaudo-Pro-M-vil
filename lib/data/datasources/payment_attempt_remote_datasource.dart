import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/entities/payment_attempt_entity.dart';

/// POST /api/payment-attempts (status PAID o NOT_PAID).
/// GET /api/payment-attempts?business_id=&credit_id=&client_id=&user_id=&status= para pintar en card cuotas atrasadas.
abstract class PaymentAttemptRemoteDataSource {
  Future<PaymentAttemptEntity> createPaymentAttempt({
    required String creditId,
    required String clientId,
    required String status,
    required String userId,
    required String businessId,
    String? businessCode,
    DateTime? attemptDate,
    String? collectionId,
    int accumulatedNoPaymentDays = 0,
    String? notes,
  });

  Future<List<PaymentAttemptEntity>> getPaymentAttempts({
    String? businessId,
    String? creditId,
    String? clientId,
    String? userId,
    String? status,
  });

  /// GET /api/payment-attempts/credit/{creditId}. Para pintar accumulated_no_payment_days en Mi cartera.
  Future<List<PaymentAttemptEntity>> getPaymentAttemptsByCreditId(
      String creditId);
}

class PaymentAttemptRemoteDataSourceImpl
    implements PaymentAttemptRemoteDataSource {
  @override
  Future<PaymentAttemptEntity> createPaymentAttempt({
    required String creditId,
    required String clientId,
    required String status,
    required String userId,
    required String businessId,
    String? businessCode,
    DateTime? attemptDate,
    String? collectionId,
    int accumulatedNoPaymentDays = 0,
    String? notes,
  }) async {
    final url = ApiConfig.buildApiUrl('/api/payment-attempts');
    // accumulated_no_payment_days siempre se envía (1, 2, 3... según cuántos NOT_PAID haya)
    final body = <String, dynamic>{
      'credit_id': creditId,
      'client_id': clientId,
      'status': status,
      'user_id': userId,
      'business_id': businessId,
      'attempt_date': (attemptDate ?? DateTime.now()).toUtc().toIso8601String(),
      'accumulated_no_payment_days': accumulatedNoPaymentDays,
      'notes': notes ?? 'string',
    };
    if (businessCode != null && businessCode.isNotEmpty) {
      body['business_code'] = businessCode;
    }
    if (collectionId != null && collectionId.isNotEmpty) {
      body['collection_id'] = collectionId;
    }
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Error al registrar intento de pago: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err is Map<String, dynamic>) {
          final m = err['message'] ?? err['error'] ?? err['detail'];
          if (m != null) msg = m is String ? m : m.toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return _fromJson(raw);
  }

  @override
  Future<List<PaymentAttemptEntity>> getPaymentAttempts({
    String? businessId,
    String? creditId,
    String? clientId,
    String? userId,
    String? status,
  }) async {
    final query = <String, String>{};
    if (businessId != null && businessId.isNotEmpty)
      query['business_id'] = businessId;
    if (creditId != null && creditId.isNotEmpty) query['credit_id'] = creditId;
    if (clientId != null && clientId.isNotEmpty) query['client_id'] = clientId;
    if (userId != null && userId.isNotEmpty) query['user_id'] = userId;
    if (status != null && status.isNotEmpty) query['status'] = status;
    final url = ApiConfig.buildApiUrlWithQuery('/api/payment-attempts', query);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          'Error al obtener intentos de pago: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    if (body is! List) return [];
    return body
        .map((e) => _fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<PaymentAttemptEntity>> getPaymentAttemptsByCreditId(
      String creditId) async {
    final url = ApiConfig.buildApiUrl('/api/payment-attempts/credit/$creditId');
    debugPrint('[PaymentAttempts] GET $url');
    final response = await http.get(Uri.parse(url));
    debugPrint('[PaymentAttempts] status=${response.statusCode} body=${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    if (response.statusCode != 200) {
      debugPrint('[PaymentAttempts] Error: status ${response.statusCode}');
      return [];
    }
    final body = jsonDecode(response.body);
    // Manejar envelope { data: [...] } o array directo
    List<dynamic>? rawList;
    if (body is List) {
      rawList = body;
    } else if (body is Map<String, dynamic>) {
      final inner = body['data'] ?? body['payment_attempts'] ?? body['attempts'];
      if (inner is List) {
        rawList = inner;
      } else {
        // Objeto único
        return [_fromJson(body)];
      }
    }
    if (rawList == null || rawList.isEmpty) return [];
    return rawList
        .map((e) => _fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static PaymentAttemptEntity _fromJson(Map<String, dynamic> json) {
    DateTime? attemptDate;
    final ad = json['attempt_date'] ?? json['attemptDate'];
    if (ad != null) {
      if (ad is String) attemptDate = DateTime.tryParse(ad);
    }
    return PaymentAttemptEntity(
      id: (json['id'] ?? json['payment_attempt_id'])?.toString(),
      creditId: (json['credit_id'] ?? json['creditId'] ?? '').toString(),
      clientId: (json['client_id'] ?? json['clientId'] ?? '').toString(),
      status: (json['status'] ?? 'NOT_PAID').toString(),
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      businessId: (json['business_id'] ?? json['businessId'])?.toString(),
      businessCode: (json['business_code'] ?? json['businessCode'])?.toString(),
      attemptDate: attemptDate,
      collectionId: (json['collection_id'] ?? json['collectionId'])?.toString(),
      accumulatedNoPaymentDays: _intFrom(json['accumulated_no_payment_days'] ??
          json['accumulatedNoPaymentDays']),
      notes: (json['notes'] as String?),
    );
  }

  static int _intFrom(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
