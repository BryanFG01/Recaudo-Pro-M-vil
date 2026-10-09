import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Campo de texto con etiqueta. Fondo suave sin borde; borde fino al enfocar.
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines,
    this.inputFormatters,
  });

  OutlineInputBorder _border(Color? color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        borderSide: color == null ? BorderSide.none : BorderSide(color: color, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          inputFormatters: inputFormatters,
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary(context)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary(context))
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surfaceLight(context),
            border: _border(null),
            enabledBorder: _border(null),
            focusedBorder: _border(AppColors.textPrimary(context)),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error),
          ),
        ),
      ],
    );
  }
}
