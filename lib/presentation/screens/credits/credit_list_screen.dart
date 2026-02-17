import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/client_entity.dart';
import '../../providers/credit_provider.dart';
import '../../providers/client_provider.dart';

class CreditListScreen extends ConsumerStatefulWidget {
  const CreditListScreen({super.key});

  @override
  ConsumerState<CreditListScreen> createState() => _CreditListScreenState();
}

class _CreditListScreenState extends ConsumerState<CreditListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.myWallet,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                hintText: AppStrings.searchByNameOrId,
                hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary(context)),
                filled: true,
                fillColor: AppColors.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),
          // Credits List
          Expanded(
            child: creditsAsync.when(
              data: (credits) {
                if (credits.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay créditos disponibles',
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: credits.length,
                  itemBuilder: (context, index) {
                    final credit = credits[index];
                    return _buildCreditCard(credit);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error: ${error.toString()}',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(credit) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return FutureBuilder<ClientEntity?>(
      future: ref.read(clientRepositoryProvider).getClientById(credit.clientId),
      builder: (context, snapshot) {
        final client = snapshot.data;
        final clientName = client?.name ?? 'Cliente';
        final clientPhone = client?.phone ?? '';

        return InkWell(
          onTap: () {
            if (client != null) {
              context.push('/client-visit/${client.id}');
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    clientName,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: AppColors.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text(
                        clientPhone,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    AppStrings.lastPayment,
                    formatter.format(credit.lastPaymentAmount),
                  ),
                  _buildInfoItem(
                    AppStrings.installmentValue,
                    formatter.format(credit.installmentAmount),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    AppStrings.overdueInstallments,
                    credit.overdueInstallments.toString(),
                    isWarning: credit.overdueInstallments > 0,
                  ),
                  _buildInfoItem(
                    AppStrings.totalBalance,
                    formatter.format(credit.totalBalance),
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value,
      {bool isWarning = false, bool isPrimary = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isPrimary
                  ? AppColors.primary
                  : isWarning
                      ? AppColors.warning
                      : AppColors.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

