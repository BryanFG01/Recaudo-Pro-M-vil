/// Validación del formulario de cliente + crédito (funciones puras, con tests).
library;

/// Mensaje si un campo obligatorio está vacío (o solo tiene espacios); null si está bien.
String? requiredField(String? value, String fieldName) =>
    (value == null || value.trim().isEmpty) ? 'Por favor ingresa el $fieldName' : null;

/// Campos obligatorios vacíos, en el orden del formulario.
List<String> missingClientFields({required String firstName, required String lastName, required String phone}) => [
      if (firstName.trim().isEmpty) 'nombre',
      if (lastName.trim().isEmpty) 'apellido',
      if (phone.trim().isEmpty) 'teléfono',
    ];

/// "nombre" · "nombre y apellido" · "nombre, apellido y teléfono".
String joinFieldNames(List<String> fields) {
  if (fields.length <= 1) return fields.join();
  return '${fields.sublist(0, fields.length - 1).join(', ')} y ${fields.last}';
}

/// Qué impide guardar, para mostrarlo en un aviso; null si se puede guardar.
/// Se revisa todo ANTES de crear el cliente (si no, quedaría creado sin su crédito).
String? newClientFormError({
  required String firstName,
  required String lastName,
  required String phone,
  required bool hasCreditAmount,
  required int collectionDays,
}) {
  final missing = missingClientFields(firstName: firstName, lastName: lastName, phone: phone);
  if (missing.isNotEmpty) {
    final noun = missing.length == 1 ? 'Falta el campo' : 'Faltan los campos';
    return '$noun: ${joinFieldNames(missing)}';
  }
  if (hasCreditAmount && collectionDays <= 0) {
    return 'Las fechas del crédito deben incluir al menos un día de cobro (lunes a sábado)';
  }
  return null;
}
