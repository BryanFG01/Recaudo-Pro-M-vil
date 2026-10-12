import 'package:flutter_test/flutter_test.dart';
import 'package:recaudo_pro/domain/services/credit_rules.dart';

void main() {
  group('Días de cobro', () {
    test('una semana completa tiene 6 días de cobro (sin domingo)', () {
      // Lunes 5 a domingo 11 de octubre de 2026
      expect(countCollectionDays(DateTime(2026, 10, 5), DateTime(2026, 10, 11)), 6);
    });

    test('incluye el primer y el último día', () {
      expect(countCollectionDays(DateTime(2026, 10, 5), DateTime(2026, 10, 5)), 1);
    });

    test('un crédito que empieza y termina en domingo no cuenta días', () {
      expect(countCollectionDays(DateTime(2026, 10, 11), DateTime(2026, 10, 11)), 0);
    });

    test('ignora la hora del día', () {
      expect(countCollectionDays(DateTime(2026, 10, 5, 23, 59), DateTime(2026, 10, 6, 0, 1)), 2);
    });

    test('30 días calendario desde un lunes son 26 de cobro', () {
      // Del 5 de octubre al 3 de noviembre: 4 domingos (11, 18, 25 oct y 1 nov)
      expect(countCollectionDays(DateTime(2026, 10, 5), DateTime(2026, 11, 3)), 26);
    });

    test('fin antes del inicio = 0 días', () {
      expect(countCollectionDays(DateTime(2026, 10, 10), DateTime(2026, 10, 5)), 0);
    });
  });

  group('Comprobante de pago', () {
    // El crédito de la captura: 1.000.000 + 200.000 de interés en 27 cuotas de 44.444,44
    ReceiptFigures receipt(double paid) => receiptFigures(
        totalAmount: 1000000, totalInterest: 200000, installmentAmount: 44444.44, totalInstallments: 27, paid: paid);

    test('el saldo incluye el interés (antes salía en 0)', () {
      final r = receipt(44444.44);
      expect(r.totalToPay, 1200000);
      expect(r.balance, closeTo(1155555.56, 0.01));
      expect(r.isPaidOff, isFalse);
    });

    test('dice qué cuota se pagó: 1 de 27, 2 de 27...', () {
      expect(receipt(44444.44).installmentNumber, 1);
      expect(receipt(88888.88).installmentNumber, 2); // dos cuotas exactas, sin falso "abono"
      expect(receipt(88888.88).isPartialInstallment, isFalse);
      expect(receipt(88888.88).pendingInstallments, 25);
    });

    test('un abono que no completa la cuota se marca como abono de la siguiente', () {
      final r = receipt(94444.44); // 2 cuotas + 5.555
      expect(r.installmentNumber, 3);
      expect(r.isPartialInstallment, isTrue);
      expect(r.pendingInstallments, 25);
    });

    test('pagado completo: saldo 0 y última cuota', () {
      final r = receipt(1200000);
      expect(r.balance, 0);
      expect(r.isPaidOff, isTrue);
      expect(r.installmentNumber, 27);
      expect(r.pendingInstallments, 0);
    });

    test('créditos sin interés registrado', () {
      final r = receiptFigures(totalAmount: 100000, totalInterest: null, installmentAmount: 10000, totalInstallments: 10, paid: 30000);
      expect(r.balance, 70000);
      expect(r.installmentNumber, 3);
    });
  });

  group('Pesos enteros (sin centavos que descuadren la caja)', () {
    test('la cuota se redondea hacia arriba al peso: 1.200.000 / 27 = 44.445', () {
      expect(dailyInstallment(amount: 1000000, interestPercent: 20, collectionDays: 27), 44445);
      expect(dailyInstallment(amount: 500000, interestPercent: 20, collectionDays: 24), 25000); // exacta
    });

    test('cuota completa: pesos enteros y la última no pasa del saldo', () {
      expect(fullInstallmentPayment(installmentAmount: 44444.44, balance: 1105555.56), 44445);
      expect(fullInstallmentPayment(installmentAmount: 44445, balance: 9000), 9000);
    });

    test('el interés queda en pesos enteros', () {
      expect(interestAmount(amount: 333333, interestPercent: 15), 50000); // 49.999,95 → 50.000
    });
  });

  group('Cuota diaria', () {
    test('monto + interés repartido en los días de cobro', () {
      // 500.000 al 20% = 600.000 en 24 días = 25.000 diarios
      expect(totalToPay(amount: 500000, interestPercent: 20), 600000);
      expect(dailyInstallment(amount: 500000, interestPercent: 20, collectionDays: 24), 25000);
    });

    test('sin días de cobro o sin monto la cuota es 0', () {
      expect(dailyInstallment(amount: 500000, interestPercent: 20, collectionDays: 0), 0);
      expect(dailyInstallment(amount: 0, interestPercent: 20, collectionDays: 24), 0);
    });
  });
}
