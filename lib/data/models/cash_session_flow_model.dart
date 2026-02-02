import '../../domain/entities/cash_session_flow_entity.dart';

class CashSessionFlowModel extends CashSessionFlowEntity {
  const CashSessionFlowModel({
    required super.cashSessionId,
    super.businessId,
    super.userId,
    super.sessionDate,
    required super.initialBalance,
    super.allowedToWithdraw,
    super.sessionCreatedAt,
    super.sessionUpdatedAt,
    super.totalCredits,
    super.totalCollected,
    super.totalWithdrawalsApproved,
    super.cajaInicialRestante,
    super.totalRecaudoMostrado,
    super.saldoDisponible,
    super.efectivoEnCaja,
  });

  factory CashSessionFlowModel.fromJson(Map<String, dynamic> json) {
    return CashSessionFlowModel(
      cashSessionId: (json['cash_session_id'] ?? '').toString(),
      businessId: (json['business_id'] ?? json['businessId'])?.toString(),
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      sessionDate: (json['session_date'] ?? json['sessionDate'])?.toString(),
      initialBalance: _num(json['initial_balance'] ?? json['initialBalance']),
      allowedToWithdraw: json['allowed_to_withdraw'] ?? json['allowedToWithdraw'] ?? true,
      sessionCreatedAt: _date(json['session_created_at'] ?? json['sessionCreatedAt']),
      sessionUpdatedAt: _date(json['session_updated_at'] ?? json['sessionUpdatedAt']),
      totalCredits: _num(json['total_credits'] ?? json['totalCredits']),
      totalCollected: _num(json['total_collected'] ?? json['totalCollected']),
      totalWithdrawalsApproved: _num(json['total_withdrawals_approved'] ?? json['totalWithdrawalsApproved']),
      cajaInicialRestante: _num(json['caja_inicial_restante'] ?? json['cajaInicialRestante']),
      totalRecaudoMostrado: _num(json['total_recaudo_mostrado'] ?? json['totalRecaudoMostrado']),
      saldoDisponible: _num(json['saldo_disponible'] ?? json['saldoDisponible']),
      efectivoEnCaja: _num(json['efectivo_en_caja'] ?? json['efectivoEnCaja']),
    );
  }

  /// Parsea montos del API. Acepta número o string: US "177320.43", miles "297.000", EU "177.320,43".
  static double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return 0.0;
      // Formato EU: coma decimal y punto miles (ej. "177.320,43") → quitar puntos, coma → punto
      if (s.contains(',') && s.contains('.')) {
        final normalized = s.replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(normalized) ?? 0.0;
      }
      if (s.contains(',')) {
        return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
      }
      // Punto: puede ser miles "297.000" (3 dígitos tras el punto) o decimal "177320.43"
      if (s.contains('.')) {
        final parts = s.split('.');
        if (parts.length == 2 && parts[1].length == 3 && int.tryParse(parts[1]) != null) {
          return double.tryParse(s.replaceAll('.', '')) ?? 0.0;
        }
      }
      return double.tryParse(s) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
