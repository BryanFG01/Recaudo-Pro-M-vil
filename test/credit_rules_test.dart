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
