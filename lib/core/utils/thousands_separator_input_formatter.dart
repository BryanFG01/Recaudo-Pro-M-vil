import 'package:flutter/services.dart';

/// Formatea el texto con punto como separador de miles (ej: 20.000) para que el monto se distinga mejor.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const String _separator = '.';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue();
    final formatted = _addThousandsSeparator(digitsOnly);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addThousandsSeparator(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_separator);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Parsea el valor mostrado (ej: "20.000") al número (20000).
  static double? parse(String text) {
    final cleaned = text.replaceAll(_separator, '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
