import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/config/api_config.dart';
import 'api_client.dart';
import '../../domain/entities/payment_attempt_entity.dart';
import 'pending_writes_sender.dart';

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
  final ApiClient _api = ApiClient.instance;
  final PendingWritesSender _writes = PendingWritesSender.instance;

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
    // accumulated_no_payment_days siempre se envía (1, 2, 3... según cuántos NOT_PAID haya).
    // El id lo pone la app: reenviarlo desde la cola sin conexión no lo duplica.
    final body = <String, dynamic>{
      'id': const Uuid().v4(),
      'credit_id': creditId,
      'client_id': clientId,
      'status': status,
      'user_id': userId,
      'business_id': businessId,
      'attempt_date': (attemptDate ?? DateTime.now()).toUtc().toIso8601String(),
      'accumulated_no_payment_days': accumulatedNoPaymentDays,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    if (businessCode != null && businessCode.isNotEmpty) {
      body['business_code'] = businessCode;
    }
    if (collectionId != null && collectionId.isNotEmpty) {
      body['collection_id'] = collectionId;
    }
    final result = await _writes.submit(path: '/api/payment-attempts', body: body, userId: userId);
    final response = result.response;
    if (response == null) return _fromJson(result.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(PendingWritesSender.errorMessage(response));
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
    if (businessId != null && businessId.isNotEmpty) {
      query['business_id'] = businessId;
    }
    if (creditId != null && creditId.isNotEmpty) query['credit_id'] = creditId;
    if (clientId != null && clientId.isNotEmpty) query['client_id'] = clientId;
    if (userId != null && userId.isNotEmpty) query['user_id'] = userId;
    if (status != null && status.isNotEmpty) query['status'] = status;
    final url = ApiConfig.buildApiUrlWithQuery('/api/payment-attempts', query);
    final response = await _api.get(Uri.parse(url));
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
    final response = await _api.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
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
