import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/closing_balance_storage.dart';
import '../../../domain/entities/daily_summary_by_user_entity.dart';
import '../../../domain/entities/daily_summary_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cash_session_provider.dart';
import '../../providers/closing_balance_provider.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class StatisticsDashboardScreen extends ConsumerWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = user != null
        ? ref.watch(dailySummaryByUserProvider(user.id))
        : const AsyncValue<DailySummaryByUserEntity>.data(
            DailySummaryByUserEntity(totals: DailySummaryTotalsEntity()));

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          AppStrings.collectionSummary,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: AppColors.textPrimary(context)),
            tooltip: 'Actualizar',
            onPressed: () {
              if (user != null) {
                ref.invalidate(dailySummaryByUserProvider(user.id));
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary(context)),
            onPressed: () {},
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) =>
            _buildContent(context, ref, summary, user?.id ?? ''),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppColors.textSecondary(context)),
                const SizedBox(height: 16),
                Text(
                  'No se pudieron cargar los reportes',
                  style: TextStyle(
                      color: AppColors.textSecondary(context), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  style: TextStyle(
                      color: AppColors.textSecondary(context), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      DailySummaryByUserEntity summary, String userId) {
    final formatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2, locale: 'es');
    final dateFormatter = DateFormat("EEE d 'de' MMMM yyyy", 'es');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Item del día: el que coincida con session_date hoy; si no hay, el primero (más reciente)
    DailySummaryEntity? todayItem;
    for (final item in summary.items) {
      if (item.sessionDate != null) {
        final d = item.sessionDate!;
        if (d.year == today.year && d.month == today.month && d.day == today.day) {
          todayItem = item;
          break;
        }
      }
    }
    todayItem ??= summary.items.isNotEmpty ? summary.items.first : null;
    final totals = summary.totals;

    final lastClosing = ref.watch(lastClosingDataProvider).valueOrNull;
    // Caja actual: la única que varía durante el día (priorizar totals desde la API)
    final double cajaActual = totals.cajaActual ?? todayItem?.cajaActual ?? 0;
    // Caja inicial: congelada; si ya cerraste día, ese cierre es la caja inicial (hoy = la que será mañana; mañana = la de ayer)
    final double cajaInicial = lastClosing?.balance ?? todayItem?.initialBalance ?? 0;
    final double recaudoDelDia = totals.totalRecaudo;
    final double gastos = totals.totalGastos;
    final double retiros = totals.totalRetiros;
    final double ventas = totals.totalVentas;
    // Ingreso: totals.ingreso_actual (API) o fallback al ítem del día
    final double ingreso = totals.totalIngresos > 0
        ? totals.totalIngresos
        : (todayItem?.totalIngresos ?? 0);

    return RefreshIndicator(
      onRefresh: () async {
        if (userId.isNotEmpty) {
          ref.invalidate(dailySummaryByUserProvider(userId));
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fecha
            Text(
              dateFormatter.format(now),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Cards principales: Caja actual + Caja inicial
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildMainCard(
                    context,
                    icon: Icons.account_balance_wallet,
                    label: 'Caja actual',
                    value: formatter.format(cajaActual),
                    subtitle:
                        'Caja inicial + Recaudo - Retiros - Gastos\n- Ventas',
                    valueColor:
                        cajaActual >= 0 ? AppColors.textPrimary(context) : AppColors.error,
                    borderColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildMainCard(
                    context,
                    label: 'Caja inicial',
                    value: formatter.format(cajaInicial),
                    valueColor: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botón Cerrar día
            _buildCloseDayButton(context, ref, userId, todayItem, cajaActual),
            const SizedBox(height: 20),

            // Filas de detalle
            _buildDetailRow(context, 'Recaudo del día', formatter.format(recaudoDelDia)),
            _buildDetailRow(context, 'Gastos', formatter.format(gastos)),
            _buildDetailRow(context, 'Retiros', formatter.format(retiros)),
            _buildDetailRow(
                context, 'Ventas (lo que se presta)', formatter.format(ventas)),
            // Ingreso solo se muestra cuando hay ingreso; al cerrar caja no se muestra (0 o sin dato)
            if (ingreso > 0)
              _buildDetailRow(context, 'Ingreso', formatter.format(ingreso)),
            _buildDetailRow(
                context, 'Caja inicial', formatter.format(cajaInicial)),
            const SizedBox(height: 28),

            // Módulos
            Text(
              'Módulos',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildModuleCard(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Retiros',
                    subtitle: 'Solo lista de retiros',
                    onTap: () => context.push('/report-withdrawals'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModuleCard(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Gastos',
                    subtitle: 'ver gastos',
                    onTap: () => context.push('/report-expenses'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(
    BuildContext context, {
    IconData? icon,
    required String label,
    required String value,
    String? subtitle,
    Color? valueColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCloseDayButton(BuildContext context, WidgetRef ref,
      String userId, DailySummaryEntity? todayItem, double cajaActualToUse) {
    return InkWell(
      onTap: () => _showCloseDayDialog(context, ref, userId, todayItem, cajaActualToUse),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cerrar día (caja actual \u2192 caja inicial mañana)',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCloseDayDialog(BuildContext context, WidgetRef ref,
      String userId, DailySummaryEntity? todayItem, double cajaActualToUse) async {
    final formatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2, locale: 'es');
    final cajaActual = cajaActualToUse;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar día',
          style: TextStyle(
            color: AppColors.textPrimary(ctx),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Se guardará la caja actual (${formatter.format(cajaActual)}) como caja inicial para mañana.\n\n¿Deseas continuar?',
          style: TextStyle(color: AppColors.textSecondary(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel,
                style: TextStyle(color: AppColors.textSecondary(ctx))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.confirm,
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final totals = ref.read(dailySummaryByUserProvider(userId)).valueOrNull?.totals;
      await saveClosingBalance(
        userId,
        cajaActual,
        today,
        recaudo: todayItem?.totalRecaudo ?? totals?.totalRecaudo ?? 0,
        retiros: todayItem?.totalRetiros ?? totals?.totalRetiros ?? 0,
        ventas: todayItem?.totalVentas ?? totals?.totalVentas ?? 0,
        gastos: todayItem?.totalGastos ?? totals?.totalGastos ?? 0,
        ingreso: todayItem?.totalIngresos ?? totals?.totalIngresos ?? 0,
      );
      ref.invalidate(lastClosingDataProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Día cerrado correctamente.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
