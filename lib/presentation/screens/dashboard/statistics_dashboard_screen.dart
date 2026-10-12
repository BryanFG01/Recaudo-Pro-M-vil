import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/daily_summary_by_user_entity.dart';
import '../../../domain/entities/daily_summary_entity.dart';
import '../../../domain/services/cash_rules.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cash_session_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../../core/utils/currency_format.dart';

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
            fontWeight: FontWeight.w600,
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
    final formatter = AppCurrency.formatter;
    final dateFormatter = DateFormat("EEE d 'de' MMMM yyyy", 'es');
    final now = DateTime.now();

    // Todas las cifras son de la caja actual (la API calcula la caja con la misma fórmula)
    final session = currentSessionOf(summary);
    final bool isClosed = session != null && !session.isOpen;
    final double cajaActual = session?.cajaActual ?? 0;
    final double cajaInicial = session?.initialBalance ?? 0;
    // Cerrada: la caja final ya es la caja inicial con la que arranca la próxima apertura
    final double topInitial = isClosed ? nextInitialBalance(session) : cajaInicial;
    final double recaudo = session?.totalRecaudo ?? 0;
    final double gastos = session?.totalGastos ?? 0;
    final double retiros = session?.totalRetiros ?? 0;
    final double ventas = session?.totalVentas ?? 0;
    final double retirosPendientes = session?.totalRetirosPendientes ?? 0;

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
                    label: isClosed ? 'Caja final' : 'Caja actual',
                    value: formatter.format(cajaActual),
                    subtitle: isClosed
                        ? 'Guardada al cerrar la caja'
                        : 'Caja inicial + Recaudo - Ventas\n- Retiros - Gastos',
                    valueColor:
                        cajaActual >= 0 ? AppColors.textPrimary(context) : AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildMainCard(
                    context,
                    label: 'Caja inicial',
                    value: formatter.format(topInitial),
                    subtitle: isClosed ? 'Con esta inicias al abrir' : null,
                    valueColor: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSessionStatus(context, session),
            const SizedBox(height: 12),

            // Abrir o cerrar caja según su estado
            _buildSessionButton(context, ref, userId, session),
            const SizedBox(height: 20),

            // Filas de detalle (de la caja actual o de la que se cerró): cuadran con la cifra de arriba
            if (isClosed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Detalle de la caja cerrada',
                    style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            _buildDetailRow(context, 'Caja inicial', formatter.format(cajaInicial)),
            _buildDetailRow(context, '+ Recaudo', formatter.format(recaudo)),
            _buildDetailRow(context, '− Ventas (lo que se presta)', formatter.format(ventas)),
            _buildDetailRow(context, '− Retiros aprobados', formatter.format(retiros)),
            _buildDetailRow(context, '− Gastos', formatter.format(gastos)),
            if (retirosPendientes > 0)
              _buildDetailRow(context, 'Retiros por aprobar (aún no restan)',
                  formatter.format(retirosPendientes)),
            const SizedBox(height: 28),

            // Módulos
            Text(
              'Módulos',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
                    subtitle: 'Ver gastos',
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                _buildIconChip(icon, size: 28, iconSize: 16),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "Caja abierta · desde el 12 oct" o "Caja cerrada a las 6:40 p. m. · caja final $X".
  Widget _buildSessionStatus(BuildContext context, DailySummaryEntity? session) {
    final String text;
    final Color color;
    if (session == null) {
      text = 'No tienes una caja abierta';
      color = AppColors.textSecondary(context);
    } else if (session.isOpen) {
      final since = session.sessionDate == null ? '' : ' · del ${DateFormat("d 'de' MMMM", 'es').format(session.sessionDate!)}';
      text = 'Caja abierta$since';
      color = AppColors.success;
    } else {
      final at = session.closedAt == null ? '' : ' a las ${DateFormat.jm('es').format(session.closedAt!.toLocal())}';
      final closing = AppCurrency.format(session.closingBalance ?? session.cajaActual);
      text = 'Caja cerrada$at · caja final $closing';
      color = AppColors.textSecondary(context);
    }
    return Row(
      children: [
        Icon(session?.isOpen == true ? Icons.lock_open : Icons.lock_outline, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildSessionButton(BuildContext context, WidgetRef ref, String userId, DailySummaryEntity? session) {
    final isOpen = session?.isOpen == true;
    return InkWell(
      onTap: () => isOpen
          ? _closeSession(context, ref, userId, session!)
          : _openSession(context, ref, userId, session),
      borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          border: Border.all(color: AppColors.textSecondary(context), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isOpen ? Icons.lock_clock : Icons.lock_open,
                color: AppColors.textPrimary(context), size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isOpen ? 'Cerrar caja' : 'Abrir caja',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cerrar: valida que no queden cobros sin enviar ni retiros por aprobar y confirma con el detalle.
  Future<void> _closeSession(BuildContext context, WidgetRef ref, String userId, DailySummaryEntity session) async {
    final blocker = closeCashBlocker(
      pendingSync: ref.read(syncStatusProvider).pending,
      pendingWithdrawals: session.totalRetirosPendientes,
    );
    if (blocker != null) {
      _showMessage(context, blocker, AppColors.error);
      return;
    }
    final formatter = AppCurrency.formatter;
    final confirmed = await _confirm(
      context,
      title: 'Cerrar caja',
      message: 'Caja inicial ${formatter.format(session.initialBalance)}\n'
          '+ Recaudo ${formatter.format(session.totalRecaudo)}\n'
          '− Ventas ${formatter.format(session.totalVentas)}\n'
          '− Retiros ${formatter.format(session.totalRetiros)}\n'
          '− Gastos ${formatter.format(session.totalGastos)}\n\n'
          'Caja final: ${formatter.format(session.cajaActual)}\n\n'
          'Será la caja inicial de tu próxima caja. Si necesitas seguir trabajando hoy puedes volver a abrirla.',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(cashSessionActionsProvider).close(userId, session.cashSessionId);
      if (context.mounted) _showMessage(context, 'Caja cerrada.', AppColors.success);
    } catch (e) {
      if (context.mounted) _showMessage(context, e.toString().replaceFirst('Exception: ', ''), AppColors.error);
    }
  }

  /// Abrir: caja nueva (a cualquier hora) con caja inicial = caja final de la anterior.
  Future<void> _openSession(BuildContext context, WidgetRef ref, String userId, DailySummaryEntity? last) async {
    final formatter = AppCurrency.formatter;
    final message = last == null
        ? 'Se abrirá tu caja para registrar cobros, ventas, gastos y retiros.'
        : 'Se abrirá una caja nueva con caja inicial ${formatter.format(nextInitialBalance(last))} '
            '(tu caja final). Si el administrador te recarga, se suma a esa caja inicial.';
    final confirmed = await _confirm(context, title: 'Abrir caja', message: message);
    if (!confirmed || !context.mounted) return;
    try {
      final opened = await ref.read(cashSessionActionsProvider).open(userId);
      if (context.mounted) {
        _showMessage(context, 'Caja abierta · caja inicial ${formatter.format(opened.initialBalance)}', AppColors.success);
      }
    } catch (e) {
      if (context.mounted) _showMessage(context, e.toString().replaceFirst('Exception: ', ''), AppColors.error);
    }
  }

  Future<bool> _confirm(BuildContext context, {required String title, required String message}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
        title: Text(title, style: TextStyle(color: AppColors.textPrimary(ctx), fontWeight: FontWeight.w600)),
        content: Text(message, style: TextStyle(color: AppColors.textSecondary(ctx))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel, style: TextStyle(color: AppColors.textSecondary(ctx))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.confirm,
                style: TextStyle(color: AppColors.textPrimary(ctx), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _showMessage(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Column(
          children: [
            _buildIconChip(icon, size: 48, iconSize: 26),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Chip mint con icono (acento de DESIGN.MD).
  Widget _buildIconChip(IconData icon,
      {required double size, required double iconSize}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Icon(icon, color: AppColors.carbon, size: iconSize),
    );
  }
}
