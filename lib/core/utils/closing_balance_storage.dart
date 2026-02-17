import 'package:shared_preferences/shared_preferences.dart';

/// Claves para persistir "caja actual" al cerrar el día; al otro día se usa como caja inicial.
const String _keyLastClosingBalance = 'last_closing_balance';
const String _keyLastClosingDate = 'last_closing_date';
const String _keyLastClosingRecaudo = 'last_closing_recaudo';
const String _keyLastClosingRetiros = 'last_closing_retiros';
const String _keyLastClosingVentas = 'last_closing_ventas';
const String _keyLastClosingGastos = 'last_closing_gastos';
const String _keyLastClosingIngreso = 'last_closing_ingreso';

/// Resultado leído del almacenamiento.
class LastClosingData {
  final double balance;
  final String date; // yyyy-MM-dd
  final double recaudo;
  final double retiros;
  final double ventas;
  final double gastos;
  final double ingreso;

  const LastClosingData({
    required this.balance,
    required this.date,
    this.recaudo = 0.0,
    this.retiros = 0.0,
    this.ventas = 0.0,
    this.gastos = 0.0,
    this.ingreso = 0.0,
  });
}

/// Guarda el estado actual de la caja y sus componentes al cerrar, específico por usuario.
Future<void> saveClosingBalance(
  String userId,
  double balance,
  String dateYyyyMmDd, {
  double recaudo = 0.0,
  double retiros = 0.0,
  double ventas = 0.0,
  double gastos = 0.0,
  double ingreso = 0.0,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('${userId}_$_keyLastClosingBalance', balance);
  await prefs.setString('${userId}_$_keyLastClosingDate', dateYyyyMmDd);
  await prefs.setDouble('${userId}_$_keyLastClosingRecaudo', recaudo);
  await prefs.setDouble('${userId}_$_keyLastClosingRetiros', retiros);
  await prefs.setDouble('${userId}_$_keyLastClosingVentas', ventas);
  await prefs.setDouble('${userId}_$_keyLastClosingGastos', gastos);
  await prefs.setDouble('${userId}_$_keyLastClosingIngreso', ingreso);
}

/// Lee el último cierre guardado para un usuario específico.
Future<LastClosingData?> getLastClosingData(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final balance = prefs.getDouble('${userId}_$_keyLastClosingBalance');
  final date = prefs.getString('${userId}_$_keyLastClosingDate');
  if (balance == null || date == null || date.isEmpty) return null;

  return LastClosingData(
    balance: balance,
    date: date,
    recaudo: prefs.getDouble('${userId}_$_keyLastClosingRecaudo') ?? 0.0,
    retiros: prefs.getDouble('${userId}_$_keyLastClosingRetiros') ?? 0.0,
    ventas: prefs.getDouble('${userId}_$_keyLastClosingVentas') ?? 0.0,
    gastos: prefs.getDouble('${userId}_$_keyLastClosingGastos') ?? 0.0,
    ingreso: prefs.getDouble('${userId}_$_keyLastClosingIngreso') ?? 0.0,
  );
}

/// Devuelve true si [dateYyyyMmDd] es estrictamente anterior a [todayYyyyMmDd].
bool isDateBefore(String dateYyyyMmDd, String todayYyyyMmDd) {
  return dateYyyyMmDd.compareTo(todayYyyyMmDd) < 0;
}

/// Devuelve true si el día ya fue cerrado para ese usuario en la fecha dada.
bool isDayClosedToday(LastClosingData? data, String todayYyyyMmDd) {
  if (data == null) return false;
  return data.date == todayYyyyMmDd;
}
