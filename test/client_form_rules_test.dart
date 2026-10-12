import 'package:flutter_test/flutter_test.dart';
import 'package:recaudo_pro/domain/services/client_form_rules.dart';

String? errorFor({String first = 'Ana', String last = 'Pérez', String phone = '300', bool credit = false, int days = 6}) =>
    newClientFormError(firstName: first, lastName: last, phone: phone, hasCreditAmount: credit, collectionDays: days);

void main() {
  test('con los obligatorios completos se puede guardar', () {
    expect(errorFor(), isNull);
    expect(errorFor(credit: true, days: 6), isNull);
  });

  test('dice qué campo falta', () {
    expect(errorFor(phone: ''), 'Falta el campo: teléfono');
    expect(errorFor(first: '', last: ''), 'Faltan los campos: nombre y apellido');
    expect(errorFor(first: '', last: '', phone: ''), 'Faltan los campos: nombre, apellido y teléfono');
  });

  test('solo espacios cuenta como vacío', () {
    expect(errorFor(first: '   '), 'Falta el campo: nombre');
    expect(requiredField('  ', 'nombre'), 'Por favor ingresa el nombre');
    expect(requiredField('Ana', 'nombre'), isNull);
  });

  test('con monto de crédito, las fechas deben tener al menos un día de cobro', () {
    expect(errorFor(credit: true, days: 0), contains('al menos un día de cobro'));
    expect(errorFor(credit: false, days: 0), isNull); // sin crédito no importan las fechas
  });

  test('los campos faltantes se avisan antes que el problema de fechas', () {
    expect(errorFor(phone: '', credit: true, days: 0), 'Falta el campo: teléfono');
  });
}
