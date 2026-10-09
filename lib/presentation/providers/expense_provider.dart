import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense_record_entity.dart';

/// Lista de gastos registrados. Se pinta solo en Reportes > Gastos (reporte).
final expensesListProvider =
    StateProvider<List<ExpenseRecordEntity>>((ref) => []);
