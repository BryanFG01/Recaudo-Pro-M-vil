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

/// Reporte de retiros: solo la lista de retiros. El resumen (caja, ingresos, egresos, etc.) está en la vista principal de Reportes.
class WithdrawalsReportScreen extends ConsumerWidget {
  const WithdrawalsReportScreen({super.key});

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
          AppStrings.withdrawalsReport,
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
          ? Center(
              child: Text(
                'Inicia sesión para ver el reporte',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(withdrawalsByUserProvider(user.id));
              },
              child: withdrawalsAsync.when(
                data: (withdrawalsData) {
                  // Excluimos los que son gastos (marcados con [GASTO]) para que el reporte sea solo de retiros
                  final retirosOnly = withdrawalsData.withdrawals
                      .where((w) => !w.reason.startsWith('[GASTO]'))
                      .toList();
                  return _buildWithdrawalsList(
                    context,
                    retirosOnly,
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Error: ${e.toString()}',
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildWithdrawalsList(
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
              AppStrings.noWithdrawals,
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
                      w.reason,
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
