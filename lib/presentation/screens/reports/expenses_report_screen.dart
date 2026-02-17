import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/withdrawal_entity.dart';
import '../../../domain/entities/withdrawals_data_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cash_session_provider.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

/// Reporte de gastos: solo la lista de gastos (como Retiros). El registro de gasto está en Gastos.
class ExpensesReportScreen extends ConsumerWidget {
  const ExpensesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final withdrawalsAsync = user != null
        ? ref.watch(withdrawalsByUserProvider(user.id))
        : const AsyncValue<WithdrawalsDataEntity>.data(
            WithdrawalsDataEntity(withdrawals: []));

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.expenses,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: AppColors.textPrimary(context)),
            tooltip: 'Actualizar datos',
            onPressed: () {
              if (user != null) {
                ref.invalidate(withdrawalsByUserProvider(user.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Actualizando datos...'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Inicia sesión para ver el reporte'))
          : withdrawalsAsync.when(
              data: (data) {
                // Filtramos solo los que son gastos (marcados con [GASTO])
                final expenses = data.withdrawals
                    .where((w) => w.reason.startsWith('[GASTO]'))
                    .toList();
                return _buildExpensesList(context, expenses);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildExpensesList(
    BuildContext context,
    List<WithdrawalEntity> list,
  ) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 48),
          Center(
            child: Text(
              'No hay gastos registrados',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final w = list[index];
        // Limpiamos el prefijo [GASTO] del motivo para mostrarlo bonito
        final displayReason = w.reason.replaceFirst('[GASTO] ', '');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: w.isApproved
                  ? AppColors.success.withOpacity(0.5)
                  : AppColors.warning.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatter.format(w.amount),
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayReason,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    if (w.createdAt != null)
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(w.createdAt!),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: w.isApproved
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  w.isApproved
                      ? AppStrings.approved
                      : AppStrings.pendingApproval,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: w.isApproved ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
