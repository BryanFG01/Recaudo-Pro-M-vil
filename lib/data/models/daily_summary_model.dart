import '../../domain/entities/daily_summary_entity.dart';

class DailySummaryModel extends DailySummaryEntity {
  const DailySummaryModel({
    required super.cashSessionId,
    super.userId,
    super.businessId,
    required super.initialBalance,
    super.saldoDiaAnterior,
    super.totalIngresos,
    super.sessionDate,
    super.totalRecaudo,
    super.totalVentas,
    super.totalRetiros,
    super.totalGastos,
    super.cajaActual,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryModel(
      cashSessionId: (json['cash_session_id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      businessId: (json['business_id'] ?? json['businessId'])?.toString(),
      initialBalance: _num(json['initial_balance'] ?? json['initialBalance']),
      saldoDiaAnterior:
          _num(json['saldo_dia_anterior'] ?? json['saldoDiaAnterior']),
      totalIngresos: _num(json['ingreso_actual'] ?? json['ingresoActual'] ?? json['total_ingresos'] ?? json['totalIngresos']),
      sessionDate: _date(json['session_date'] ?? json['sessionDate']),
      totalRecaudo: _num(json['total_recaudo'] ?? json['totalRecaudo']),
      totalVentas: _num(json['total_ventas'] ?? json['totalVentas']),
      totalRetiros: _num(json['total_retiros'] ?? json['totalRetiros']),
      totalGastos: _num(json['total_gastos'] ?? json['totalGastos']),
      cajaActual: _num(json['caja_actual'] ?? json['cajaActual']),
    );
  }

  static double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return 0.0;
      if (s.contains(',') && s.contains('.')) {
        return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ??
            0.0;
      }
      if (s.contains(',')) {
        return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
      }
      if (s.contains('.')) {
        final parts = s.split('.');
        if (parts.length == 2 &&
            parts[1].length == 3 &&
            int.tryParse(parts[1]) != null) {
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
