import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/entities/cash_session_entity.dart';
import '../../domain/entities/cash_session_flow_entity.dart';
import '../../domain/entities/withdrawal_entity.dart';
import '../../domain/entities/withdrawals_data_entity.dart';
import '../models/cash_session_flow_model.dart';
import '../models/cash_session_model.dart';
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
}

class CashSessionRemoteDataSourceImpl implements CashSessionRemoteDataSource {
  @override
  Future<CashSessionEntity?> getCashSessionById(String id) async {
    final url = ApiConfig.buildApiUrl('/api/cash-sessions/$id');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Error al obtener sesión de caja: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CashSessionModel.fromJson(data);
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
    return CashSessionModel.fromJson(data);
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
    return WithdrawalModel.fromJson(data);
  }

  @override
  Future<WithdrawalsDataEntity> getWithdrawalsByUser(String userId) async {
    final url = ApiConfig.buildApiUrl('/api/withdrawals/user/$userId');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener retiros: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    if (body is List<dynamic>) {
      final list = body
          .map((e) =>
              WithdrawalModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return WithdrawalsDataEntity(withdrawals: list);
    }
    final data = body as Map<String, dynamic>;
    final listRaw = data['withdrawals'] as List<dynamic>? ?? [];
    final list = listRaw
        .map((e) =>
            WithdrawalModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final initialBalance = _numFrom(data['initial_balance'] ?? data['initialBalance']);
    final currentBalance = _numFrom(data['current_balance'] ?? data['currentBalance']);
    final cashSessionId = (data['cash_session_id'] ?? data['cashSessionId'])?.toString();
    return WithdrawalsDataEntity(
      withdrawals: list,
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      cashSessionId: cashSessionId?.isNotEmpty == true ? cashSessionId : null,
    );
  }

  static double? _numFrom(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
