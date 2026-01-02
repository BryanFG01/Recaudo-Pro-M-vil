import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/collection_provider.dart';

class StatisticsDashboardScreen extends ConsumerStatefulWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  ConsumerState<StatisticsDashboardScreen> createState() =>
      _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState
    extends ConsumerState<StatisticsDashboardScreen> {
  int _selectedTab = 1; // 0: Hoy, 1: Semana, 2: Mes

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider(_selectedTab));
    final recentCollectionsAsync = ref.watch(recentCollectionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          AppStrings.collectionSummary,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            Row(
              children: [
                _buildTab(0, AppStrings.today),
                const SizedBox(width: 8),
                _buildTab(1, AppStrings.week),
                const SizedBox(width: 8),
                _buildTab(2, AppStrings.month),
              ],
            ),
            const SizedBox(height: 24),
            // Summary Cards
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          AppStrings.totalCollected,
                          stats.totalCollected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          AppStrings.activeCredits,
                          stats.activeCredits.toDouble(),
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          AppStrings.clientsInArrears,
                          stats.clientsInArrears.toDouble(),
                          isNumber: true,
                          isWarning: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Recaudos por método de pago
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentMethodCard(
                          'Efectivo',
                          stats.cashCollection,
                          stats.cashCount,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPaymentMethodCard(
                          'Transacción',
                          stats.transactionCollection,
                          stats.transactionCount,
                          AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const SizedBox(height: 100),
              error: (_, __) => const SizedBox(height: 100),
            ),
            const SizedBox(height: 24),
            // Weekly Collection Chart
            statsAsync.when(
              data: (stats) => _buildWeeklyCollectionCard(stats),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),
            // Credit Status Chart
            statsAsync.when(
              data: (stats) => _buildCreditStatusCard(stats),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),
            // Recent Payments
            // const Text(
            //   AppStrings.lastPaymentsReceived,
            //   style: TextStyle(
            //     color: AppColors.textPrimary,
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // const SizedBox(height: 12),
            // recentCollectionsAsync.when(
            //   data: (collections) => ListView.builder(
            //     shrinkWrap: true,
            //     physics: const NeverScrollableScrollPhysics(),
            //     itemCount: collections.length > 3 ? 3 : collections.length,
            //     itemBuilder: (context, index) {
            //       final collection = collections[index];
            //       return _buildPaymentItem(collection);
            //     },
            //   ),
            // loading: () => const Center(child: CircularProgressIndicator()),
            // error: (_, __) => const Text('Error al cargar pagos'),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value,
      {bool isNumber = false, bool isWarning = false}) {
    final formatter = isNumber
        ? NumberFormat('#,###')
        : NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(value),
            style: TextStyle(
              color: isWarning ? AppColors.warning : AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCollectionCard(stats) {
    final maxAmount = stats.weeklyCollectionData.isNotEmpty
        ? stats.weeklyCollectionData
            .map((e) => e['amount'] as double)
            .reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTab == 0
                    ? 'Recaudo de Hoy'
                    : _selectedTab == 1
                        ? AppStrings.weeklyCollection
                        : 'Recaudo del Mes',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                    .format(stats.totalCollected),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar chart con datos reales por día
          stats.weeklyCollectionData.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No hay datos para mostrar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : _selectedTab == 2 && stats.weeklyCollectionData.length > 7
                  ? // Para el mes, mostrar en scroll horizontal si hay muchos días
                  SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: stats.weeklyCollectionData.length,
                        itemBuilder: (context, index) {
                          final data = stats.weeklyCollectionData[index];
                          final amount = data['amount'] as double;
                          final label = data['label'] as String;
                          final height =
                              maxAmount > 0 ? amount / maxAmount : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildBar(label, height, amount),
                          );
                        },
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: stats.weeklyCollectionData.map<Widget>((data) {
                        final amount = data['amount'] as double;
                        final label = data['label'] as String;
                        final height = maxAmount > 0 ? amount / maxAmount : 0.0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildBar(label, height, amount),
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double height, double amount) {
    return Column(
      children: [
        Tooltip(
          message: NumberFormat.currency(symbol: '\$', decimalDigits: 0)
              .format(amount),
          child: Container(
            width: 30,
            height: 80 * (height > 0 ? height : 0.05),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCreditStatusCard(stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.creditStatus,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Gráfica circular con datos reales
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: stats.upToDatePercentage / 100,
                      strokeWidth: 10,
                      backgroundColor: AppColors.overdue,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stats.upToDatePercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stats.activeCredits - stats.clientsInArrears}/${stats.activeCredits}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppStrings.upToDate}: ${stats.activeCredits - stats.clientsInArrears}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.overdue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppStrings.overdue}: ${stats.clientsInArrears}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Total Clientes: ${stats.totalClients}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
      String method, double amount, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                method,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                .format(amount),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'pago' : 'pagos'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(collection) {
    // This would need to fetch client name from collection
    // For now, using placeholder
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cliente', // Would be collection.clientName
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hace 15 minutos', // Would calculate from collection.paymentDate
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                .format(collection.amount),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
