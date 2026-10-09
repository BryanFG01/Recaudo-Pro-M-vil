import '../../domain/entities/daily_summary_by_user_entity.dart';
import '../../domain/entities/daily_summary_entity.dart';
import 'daily_summary_model.dart';

class DailySummaryTotalsModel extends DailySummaryTotalsEntity {
  const DailySummaryTotalsModel({
    super.totalIngresos,
    super.totalRecaudo,
    super.totalVentas,
    super.totalRetiros,
    super.totalGastos,
    super.cajaActual,
  });

  factory DailySummaryTotalsModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryTotalsModel(
      // API envía ingreso_actual; en el front se sigue mostrando como "Ingreso" (totalIngresos).
      totalIngresos: _num(json['ingreso_actual'] ?? json['ingresoActual'] ?? json['total_ingresos'] ?? json['totalIngresos']),
      totalRecaudo: _num(json['total_recaudo'] ?? json['totalRecaudo']),
      totalVentas: _num(json['total_ventas'] ?? json['totalVentas']),
      totalRetiros: _num(json['total_retiros'] ?? json['totalRetiros']),
      totalGastos: _num(json['total_gastos'] ?? json['totalGastos']),
      cajaActual: _numOpt(json['caja_actual'] ?? json['cajaActual']),
    );
  }

  static double? _numOpt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

class DailySummaryByUserModel extends DailySummaryByUserEntity {
  const DailySummaryByUserModel({
    super.items,
    required super.totals,
  });

  factory DailySummaryByUserModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<DailySummaryEntity> items = rawItems is List<dynamic>
        ? rawItems
            .map((e) =>
                DailySummaryModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : [];

    final rawTotals = json['totals'];
    final DailySummaryTotalsEntity totals = rawTotals is Map<String, dynamic>
        ? DailySummaryTotalsModel.fromJson(rawTotals)
        : const DailySummaryTotalsModel();

    return DailySummaryByUserModel(items: items, totals: totals);
  }
}
