import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_format.dart';

/// Tarjeta de indicador principal (KPI). Por defecto es la tarjeta invertida
/// (bloque negro / mint en oscuro) para destacar el dato más importante.
class StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final String subtitle;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.icon = Icons.payments_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final background = AppColors.primary;
    final foreground = AppColors.onPrimary;
    // El chip del icono contrasta con la tarjeta: mint sobre negro (claro), negro sobre mint (oscuro)
    final chipColor = foreground == AppColors.carbon ? AppColors.carbon : AppColors.mint;
    final chipIconColor = foreground == AppColors.carbon ? AppColors.mint : AppColors.carbon;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: chipIconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            AppCurrency.format(amount),
            style: TextStyle(
              color: foreground,
              fontSize: 34,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
