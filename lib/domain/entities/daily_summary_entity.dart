import 'package:equatable/equatable.dart';

/// Resumen diario de sesión de caja (GET /api/cash-sessions/daily-summary/{id}).
/// Devuelve total_recaudo, total_ventas, total_retiros, total_gastos y caja_actual
/// calculados desde la vista daily_cash_summary del backend.
class DailySummaryEntity extends Equatable {
  final String cashSessionId;
  final String? userId;
  final String? businessId;
  final double initialBalance;
  final double saldoDiaAnterior;
  final double totalIngresos;
  final DateTime? sessionDate;
  final double totalRecaudo;
  final double totalVentas;
  final double totalRetiros;
  final double totalGastos;
  final double cajaActual;

  const DailySummaryEntity({
    required this.cashSessionId,
    this.userId,
    this.businessId,
    this.initialBalance = 0,
    this.saldoDiaAnterior = 0,
    this.totalIngresos = 0,
    this.sessionDate,
    this.totalRecaudo = 0,
    this.totalVentas = 0,
    this.totalRetiros = 0,
    this.totalGastos = 0,
    this.cajaActual = 0,
  });

  @override
  List<Object?> get props => [
        cashSessionId,
        userId,
        businessId,
        initialBalance,
        saldoDiaAnterior,
        totalIngresos,
        sessionDate,
        totalRecaudo,
        totalVentas,
        totalRetiros,
        totalGastos,
        cajaActual,
      ];
}
