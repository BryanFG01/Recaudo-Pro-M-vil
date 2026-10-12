import 'package:intl/intl.dart';

/// Formato único de dinero en la app (pesos colombianos redondeados al peso): "$ 3.223.889".
/// Es el mismo criterio del panel Admin y de los avisos: sin centavos, para no confundir al cliente.
class AppCurrency {
  AppCurrency._();

  static final NumberFormat _whole = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '¤ #,##0',
  );

  /// Para el código que guarda el formateador en una variable (`formatter.format(x)`).
  static final MoneyFormatter formatter = MoneyFormatter._();

  static String format(num amount) => _whole.format(amount);
}

class MoneyFormatter {
  MoneyFormatter._();

  String format(num? amount) => AppCurrency.format(amount ?? 0);
}
