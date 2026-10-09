import 'package:intl/intl.dart';

/// Formato único de dinero en la app (pesos colombianos): "$ 1.250.000".
/// Usar siempre este formateador en lugar de crear NumberFormat.currency por pantalla.
class AppCurrency {
  AppCurrency._();

  static final NumberFormat formatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '¤ #,##0',
  );

  static String format(num amount) => formatter.format(amount);
}
