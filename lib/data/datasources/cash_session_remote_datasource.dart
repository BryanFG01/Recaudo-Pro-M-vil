import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/entities/cash_session_entity.dart';
import '../../domain/entities/cash_session_flow_entity.dart';
import '../../domain/entities/daily_summary_by_user_entity.dart';
import '../../domain/entities/daily_summary_entity.dart';
import '../../domain/entities/withdrawal_entity.dart';
import '../../domain/entities/withdrawals_data_entity.dart';
import '../models/cash_session_flow_model.dart';
import '../models/cash_session_model.dart';
import '../models/daily_summary_by_user_model.dart';
import '../models/daily_summary_model.dart';
import '../models/withdrawal_model.dart';

/// IMPORTANTE - Backend: Al actualizar o ingresar un nuevo saldo inicial (PATCH/POST initial_balance),
/// el backend NUNCA debe borrar ni reiniciar el recaudo (total_collected, collections). Solo debe
/// actualizar el campo initial_balance de la sesión existente. Perder el recaudo al cambiar el
/// saldo inicial es un error de negocio.
abstract class CashSessionRemoteDataSource {
  Future<CashSessionEntity?> getCashSessionById(String id);

  /// Flujo de caja por sesión (GET /api/cash-sessions/flow/:id).
  /// Devuelve cash_flow_by_session: caja_inicial_restante, total_collected, total_recaudo_mostrado,
  /// saldo_disponible, efectivo_en_caja (initial_balance + total_collected − retiros). Llamar de nuevo al aprobar retiros.
  Future<CashSessionFlowEntity?> getCashSessionFlow(String sessionId);

  /// Sesión activa del usuario (GET /api/cash-sessions/active?user_id=...). 404 → null.
  Future<CashSessionEntity?> getActiveCashSessionByUserId(String userId);

  /// Sesión de caja del usuario para pintar saldo inicial (GET /api/cash-sessions/user/{userId}). 404 → null.
  Future<CashSessionEntity?> getCashSessionByUserId(String userId);
  Future<WithdrawalEntity> createWithdrawal({
    required String cashSessionId,
    required String userId,
    required double amount,
    required String reason,
    bool isApproved = false,
  });

  /// GET /api/withdrawals/user/{userId}. Puede devolver array o objeto con withdrawals + initial_balance, current_balance.
  Future<WithdrawalsDataEntity> getWithdrawalsByUser(String userId);

  /// Resumen diario (GET /api/cash-sessions/daily-summary/{sessionId}).
  /// Devuelve total_recaudo, total_ventas, total_retiros, total_gastos y caja_actual.
  Future<DailySummaryEntity?> getDailySummary(String sessionId);

  /// Resumen diario por usuario (GET /api/cash-sessions/daily-summary/user/{userId}).
  /// Cuerpo: { "items": [ { cash_session_id, user_id, business_id, initial_balance, session_date, total_recaudo, total_ventas, total_retiros, total_gastos, caja_actual } ], "totals": { total_recaudo, total_ventas, total_retiros, total_gastos } }.
  Future<DailySummaryByUserEntity> getDailySummaryByUserId(String userId);

  /// GET /api/withdrawals?cash_session_id=X&user_id=Y. Lista de retiros filtrada por sesión y usuario.
  Future<List<WithdrawalEntity>> getWithdrawalsBySession({
    required String cashSessionId,
    required String userId,
  });

  /// GET /api/cash-sessions/user/{userId}. Devuelve TODAS las sesiones del usuario (no solo la primera).
  Future<List<CashSessionEntity>> getAllCashSessionsByUserId(String userId);
}

class CashSessionRemoteDataSourceImpl implements CashSessionRemoteDataSource {
  @override
  Future<CashSessionEntity?> getCashSessionById(String id) async {
    final url = ApiConfig.buildApiUrl('/api/cash-sessions/$id');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(
          'Error al obtener sesión de caja: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return CashSessionModel.fromJson(raw);
  }

  @override
  Future<CashSessionFlowEntity?> getCashSessionFlow(String sessionId) async {
    final url = ApiConfig.buildApiUrl('/api/cash-sessions/flow/$sessionId');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    Map<String, dynamic> data;
    if (body is List<dynamic> && body.isNotEmpty) {
      final first = body.first;
      data = first is Map<String, dynamic> ? first : <String, dynamic>{};
    } else if (body is Map<String, dynamic>) {
      data = body;
    } else {
      return null;
    }
    if (data.isEmpty) return null;
    return CashSessionFlowModel.fromJson(data);
  }

  @override
  Future<CashSessionEntity?> getActiveCashSessionByUserId(String userId) async {
    final url = ApiConfig.buildApiUrl(
      '/api/cash-sessions/active?user_id=${Uri.encodeComponent(userId)}',
    );
    final response = await http.get(Uri.parse(url));
    // Cualquier respuesta distinta de 200 (404, 500, etc.) → sin sesión activa; mostramos mensaje amigable
    if (response.statusCode != 200) {
      return null;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return CashSessionModel.fromJson(raw);
  }

  @override
  Future<CashSessionEntity?> getCashSessionByUserId(String userId) async {
    final url = ApiConfig.buildApiUrl('/api/cash-sessions/user/$userId');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    Map<String, dynamic>? data;
    if (body is List<dynamic> && body.isNotEmpty) {
      final first = body.first;
      data = first is Map<String, dynamic> ? first : null;
    } else if (body is Map<String, dynamic>) {
      data = body['data'] ?? body['session'] ?? body;
      if (data is! Map<String, dynamic>) data = body;
    }
    if (data == null) return null;
    return CashSessionModel.fromJson(data);
  }

  @override
  Future<WithdrawalEntity> createWithdrawal({
    required String cashSessionId,
    required String userId,
    required double amount,
    required String reason,
    bool isApproved = false,
  }) async {
    final url = ApiConfig.buildApiUrl('/api/withdrawals');
    final body = {
      'cash_session_id': cashSessionId,
      'user_id': userId,
      'amount': amount,
      'reason': reason,
      'is_approved': isApproved,
    };
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Error al crear retiro: ${response.statusCode}';
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
    return WithdrawalModel.fromJson(raw);
  }

  @override
  Future<WithdrawalsDataEntity> getWithdrawalsByUser(String userId) async {
    final url = ApiConfig.buildApiUrl('/api/withdrawals/user/$userId');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener retiros: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    // Caso 1: respuesta es directamente un array de retiros
    if (body is List<dynamic>) {
      final list = body
          .map((e) =>
              WithdrawalModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return WithdrawalsDataEntity(withdrawals: list);
    }
    // Caso 2: respuesta es un objeto con posible envelope { data: ... }
    final data = body as Map<String, dynamic>;
    // Desempaquetar envelope "data" si existe
    final innerData = data['data'];
    // Si data contiene un array directamente
    if (innerData is List<dynamic>) {
      final list = innerData
          .map((e) =>
              WithdrawalModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return WithdrawalsDataEntity(withdrawals: list);
    }
    // Si data contiene un objeto con withdrawals
    final Map<String, dynamic> source =
        innerData is Map<String, dynamic> ? innerData : data;
    // Buscar la lista de retiros en múltiples claves posibles
    final listRaw = source['withdrawals'] as List<dynamic>? ??
        source['data'] as List<dynamic>? ??
        [];
    final list = listRaw
        .map((e) =>
            WithdrawalModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final initialBalance =
        _numFrom(source['initial_balance'] ?? source['initialBalance']);
    final currentBalance =
        _numFrom(source['current_balance'] ?? source['currentBalance']);
    final cashSessionId =
        (source['cash_session_id'] ?? source['cashSessionId'])?.toString();
    return WithdrawalsDataEntity(
      withdrawals: list,
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      cashSessionId: cashSessionId?.isNotEmpty == true ? cashSessionId : null,
    );
  }

  @override
  Future<DailySummaryEntity?> getDailySummary(String sessionId) async {
    final url =
        ApiConfig.buildApiUrl('/api/cash-sessions/daily-summary/$sessionId');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    Map<String, dynamic>? data;
    if (body is Map<String, dynamic>) {
      data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
    } else if (body is List<dynamic> && body.isNotEmpty) {
      final first = body.first;
      data = first is Map<String, dynamic> ? first : null;
    }
    if (data == null || data.isEmpty) return null;
    return DailySummaryModel.fromJson(data);
  }

  @override
  Future<DailySummaryByUserEntity> getDailySummaryByUserId(String userId) async {
    final url = ApiConfig.buildApiUrl(
        '/api/cash-sessions/daily-summary/user/${Uri.encodeComponent(userId)}');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) {
      return const DailySummaryByUserEntity(totals: DailySummaryTotalsEntity());
    }
    if (response.statusCode != 200) {
      throw Exception(
          'Error al obtener resumen diario por usuario: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    // Cuerpo: { "items": [...], "totals": { ... } } en la raíz, o { "data": { "items", "totals" } }
    Map<String, dynamic> data = body is Map<String, dynamic>
        ? body
        : <String, dynamic>{};
    final inner = data['data'];
    if (inner is Map<String, dynamic> && (inner['items'] != null || inner['totals'] != null)) {
      data = inner;
    }
    return DailySummaryByUserModel.fromJson(data);
  }

  @override
  Future<List<WithdrawalEntity>> getWithdrawalsBySession({
    required String cashSessionId,
    required String userId,
  }) async {
    final url = ApiConfig.buildApiUrl(
      '/api/withdrawals?cash_session_id=${Uri.encodeComponent(cashSessionId)}&user_id=${Uri.encodeComponent(userId)}',
    );
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      return [];
    }
    final body = jsonDecode(response.body);
    List<dynamic> rawList;
    if (body is List<dynamic>) {
      rawList = body;
    } else if (body is Map<String, dynamic>) {
      final inner = body['data'] ?? body['withdrawals'];
      rawList = inner is List<dynamic> ? inner : [];
    } else {
      return [];
    }
    return rawList
        .map((e) =>
            WithdrawalModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<CashSessionEntity>> getAllCashSessionsByUserId(
      String userId) async {
    final url = ApiConfig.buildApiUrl('/api/cash-sessions/user/$userId');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    List<dynamic> rawList;
    if (body is List<dynamic>) {
      rawList = body;
    } else if (body is Map<String, dynamic>) {
      final inner = body['data'] ?? body['sessions'];
      if (inner is List<dynamic>) {
        rawList = inner;
      } else {
        // Objeto único
        return [CashSessionModel.fromJson(body)];
      }
    } else {
      return [];
    }
    return rawList
        .map((e) =>
            CashSessionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static double? _numFrom(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
