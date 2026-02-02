import 'package:equatable/equatable.dart';

/// Fila de la vista cash_flow_by_session (GET /api/cash-sessions/flow/:id).
/// saldo_disponible / efectivo_en_caja = saldo inicial + recaudo (initial_balance + total_collected − retiros aprobados).
class CashSessionFlowEntity extends Equatable {
  final String cashSessionId;
  final String? businessId;
  final String? userId;
  final String? sessionDate;
  final double initialBalance;
  final bool allowedToWithdraw;
  final DateTime? sessionCreatedAt;
  final DateTime? sessionUpdatedAt;
  final double totalCredits;
  final double totalCollected;
  final double totalWithdrawalsApproved;
  final double cajaInicialRestante;
  final double totalRecaudoMostrado;
  final double saldoDisponible;
  /// initial_balance + total_collected − retiros aprobados (efectivo en caja).
  final double efectivoEnCaja;

  const CashSessionFlowEntity({
    required this.cashSessionId,
    this.businessId,
    this.userId,
    this.sessionDate,
    required this.initialBalance,
    this.allowedToWithdraw = true,
    this.sessionCreatedAt,
    this.sessionUpdatedAt,
    this.totalCredits = 0,
    this.totalCollected = 0,
    this.totalWithdrawalsApproved = 0,
    this.cajaInicialRestante = 0,
    this.totalRecaudoMostrado = 0,
    this.saldoDisponible = 0,
    this.efectivoEnCaja = 0,
  });

  /// Saldo disponible = saldo inicial + recaudo (initial_balance + total_collected − retiros aprobados).
  /// Equivalente a efectivo_en_caja. Se calcula para garantizar la fórmula en frontend.
  double get saldoDisponibleCalculado => initialBalance + totalRecaudoMostrado;

  @override
  List<Object?> get props => [
        cashSessionId,
        businessId,
        userId,
        sessionDate,
        initialBalance,
        allowedToWithdraw,
        sessionCreatedAt,
        sessionUpdatedAt,
        totalCredits,
        totalCollected,
        totalWithdrawalsApproved,
        cajaInicialRestante,
        totalRecaudoMostrado,
        saldoDisponible,
        efectivoEnCaja,
      ];
}
