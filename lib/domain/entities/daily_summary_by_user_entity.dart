import 'package:equatable/equatable.dart';

import 'daily_summary_entity.dart';

/// Totales agregados del resumen diario por usuario.
class DailySummaryTotalsEntity extends Equatable {
  final double totalIngresos;
  final double totalRecaudo;
  final double totalVentas;
  final double totalRetiros;
  final double totalGastos;
  /// Caja actual (puede venir en totals desde la API).
  final double? cajaActual;

  const DailySummaryTotalsEntity({
    this.totalIngresos = 0,
    this.totalRecaudo = 0,
    this.totalVentas = 0,
    this.totalRetiros = 0,
    this.totalGastos = 0,
    this.cajaActual,
  });

  @override
  List<Object?> get props => [totalIngresos, totalRecaudo, totalVentas, totalRetiros, totalGastos, cajaActual];
}

/// Resumen diario por usuario (GET /api/cash-sessions/daily-summary/user/{userId}).
/// Cuerpo: { "items": [...], "totals": { total_recaudo, total_ventas, total_retiros, total_gastos } }.
class DailySummaryByUserEntity extends Equatable {
  final List<DailySummaryEntity> items;
  final DailySummaryTotalsEntity totals;

  const DailySummaryByUserEntity({
    this.items = const [],
    required this.totals,
  });

  @override
  List<Object?> get props => [items, totals];
}
