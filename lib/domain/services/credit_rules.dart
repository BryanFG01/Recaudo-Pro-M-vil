/// Reglas puras para armar un crédito diario (sin Flutter ni fechas implícitas).
library;

/// Días de cobro entre [start] y [end], ambos incluidos, sin contar domingos.
int countCollectionDays(DateTime start, DateTime end) {
  var count = 0;
  var current = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!current.isAfter(last)) {
    if (current.weekday != DateTime.sunday) count++;
    // DateTime(año, mes, día + 1) evita saltos raros por cambios de horario
    current = DateTime(current.year, current.month, current.day + 1);
  }
  return count;
}

/// Total a pagar: monto + interés simple ([interestPercent] sobre el monto).
double totalToPay({required double amount, required double interestPercent}) =>
    amount + amount * interestPercent / 100;

/// Cuota diaria: total a pagar repartido en los días de cobro (0 si no hay días o monto).
double dailyInstallment({required double amount, required double interestPercent, required int collectionDays}) {
  if (amount <= 0 || collectionDays <= 0) return 0;
  return totalToPay(amount: amount, interestPercent: interestPercent) / collectionDays;
}
