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

/// Cifras del comprobante de pago, calculadas con lo pagado (igual que la API: saldo sobre
/// prestado + interés).
class ReceiptFigures {
  final double totalToPay;
  final double paid;
  final double balance;

  /// Cuota que cubre este pago (1, 2, 3...).
  final int installmentNumber;
  final int totalInstallments;

  /// El pago no completa la cuota (abono).
  final bool isPartialInstallment;

  /// Cuotas que faltan por pagar completas.
  final int pendingInstallments;

  const ReceiptFigures({
    required this.totalToPay,
    required this.paid,
    required this.balance,
    required this.installmentNumber,
    required this.totalInstallments,
    required this.isPartialInstallment,
    required this.pendingInstallments,
  });

  bool get isPaidOff => balance <= 0;
}

/// [paid] incluye todos los pagos del crédito (y el que se está imprimiendo, si aún no se guardó).
ReceiptFigures receiptFigures({
  required double totalAmount,
  required double? totalInterest,
  required double installmentAmount,
  required int totalInstallments,
  required double paid,
}) {
  final total = totalAmount + (totalInterest ?? 0);
  final balance = total - paid > 0.5 ? total - paid : 0.0; // centavos de redondeo no cuentan como deuda
  final covered = installmentAmount > 0 ? paid / installmentAmount : 0.0;
  // Tolerancia: 2 cuotas de 44.444,44 suman 88.888,88 y deben contar como 2 cuotas completas
  final fullInstallments = (covered + 1e-6).floor().clamp(0, totalInstallments);
  final isPartial = balance > 0 && covered - fullInstallments > 1e-6;
  final current = paid <= 0 ? 0 : (isPartial ? fullInstallments + 1 : fullInstallments);
  return ReceiptFigures(
    totalToPay: total,
    paid: paid,
    balance: balance,
    installmentNumber: current.clamp(0, totalInstallments),
    totalInstallments: totalInstallments,
    isPartialInstallment: isPartial,
    pendingInstallments: balance <= 0 ? 0 : totalInstallments - fullInstallments,
  );
}

/// Interés en pesos enteros (en Colombia no se cobran centavos).
double interestAmount({required double amount, required double interestPercent}) =>
    (amount * interestPercent / 100).roundToDouble();

/// Cuota diaria en pesos enteros, redondeada hacia arriba: 1.200.000 / 27 = 44.444,44 → 44.445.
/// Con centavos la caja arrastraba ",88" y cada pantalla lo redondeaba distinto. La última cuota
/// se ajusta al saldo (ver [fullInstallmentPayment]). 0 si no hay días o monto.
double dailyInstallment({required double amount, required double interestPercent, required int collectionDays}) {
  if (amount <= 0 || collectionDays <= 0) return 0;
  return ((amount + interestAmount(amount: amount, interestPercent: interestPercent)) / collectionDays).ceilToDouble();
}

/// "Pagar cuota completa": la cuota en pesos enteros, sin pasarse del saldo (la última cierra exacto).
double fullInstallmentPayment({required double installmentAmount, required double balance}) {
  final installment = installmentAmount.ceilToDouble();
  return balance > 0 && balance < installment ? balance : installment;
}
