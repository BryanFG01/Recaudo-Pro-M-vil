import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/cash_session_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(authRepositoryProvider).signOut().then((_) {
                  ref.read(currentUserProvider.notifier).setUser(null);
                  ref.read(selectedBusinessProvider.notifier).clearBusiness();
                  context.go('/login');
                });
              },
              child: Text(
                'Aceptar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Period 0 = hoy: recaudo diario de la API (se reinicia cada 24h)
    final statsAsync = ref.watch(dashboardStatsProvider(0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pink,
            shape: BoxShape.circle,
          ),
          child: user?.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    user!.avatarUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.person, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.hello}, ${user?.name ?? 'Usuario'}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.textPrimary),
            tooltip: 'Actualizar datos',
            onPressed: () {
              final user = ref.read(currentUserProvider);
              ref.invalidate(clientsProvider);
              ref.invalidate(creditsProvider);
              ref.invalidate(dashboardStatsProvider(0));
              ref.invalidate(dashboardStatsProvider(1));
              ref.invalidate(dashboardStatsProvider(2));
              ref.invalidate(recentCollectionsProvider);
              if (user != null) {
                ref.invalidate(withdrawalsByUserProvider(user.id));
                ref.invalidate(cashSessionByUserProvider(user.id));
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Actualizando datos...'),
                  duration: Duration(seconds: 2),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            // icon de salir de la vista deslogarse
            icon:
                const Icon(Icons.logout_outlined, color: AppColors.textPrimary),
            onPressed: () {
              _showLogoutDialog(context, ref);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recaudo diario desde API (GET /api/dashboard/stats) — se reinicia cada 24h
            statsAsync.when(
              data: (stats) => StatCard(
                title: AppStrings.dailyCollection,
                amount: stats.dailyCollection,
                subtitle: 'Recaudo de hoy (se reinicia a las 00:00)',
              ),
              loading: () => const StatCard(
                title: AppStrings.dailyCollection,
                amount: 0,
                subtitle: AppStrings.todaySummary,
              ),
              error: (_, __) => const StatCard(
                title: AppStrings.dailyCollection,
                amount: 0,
                subtitle: AppStrings.todaySummary,
              ),
            ),
            const SizedBox(height: 24),

            // boton de agregar cliente nuevo card completo con icono y texto
            InkWell(
              onTap: () {
                context.push('/new-client');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_outlined,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(AppStrings.newClient,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                // DashboardCard(
                //   title: AppStrings.sales,
                //   subtitle: 'Administrar ventas',
                //   icon: Icons.shopping_cart_outlined,
                //   onTap: () {},
                // ),
                DashboardCard(
                  title: AppStrings.clients,
                  subtitle: 'Ver clientes',
                  icon: Icons.people_outline,
                  onTap: () {
                    context.push('/clients');
                  },
                ),
                DashboardCard(
                  title: AppStrings.collection,
                  subtitle: 'Realizar cobros',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () {
                    context.push('/my-wallet');
                  },
                ),
                DashboardCard(
                  title: AppStrings.cashSessionAndWithdrawals,
                  subtitle: AppStrings.cashSessionSubtitle,
                  icon: Icons.point_of_sale_outlined,
                  onTap: () {
                    context.push('/cash-session/active');
                  },
                ),
                // DashboardCard(
                //   title: AppStrings.recharges,
                //   subtitle: 'Recargas móviles',
                //   icon: Icons.phone_android_outlined,
                //   onTap: () {},
                // ),
                // DashboardCard(
                //   title: AppStrings.raffles,
                //   subtitle: 'Gestionar rifas',
                //   icon: Icons.confirmation_number_outlined,
                //   onTap: () {},
                // ),
                // DashboardCard(
                //   title: AppStrings.store,
                //   subtitle: '',
                //   icon: Icons.store_outlined,
                //   onTap: () {},
                //   showNewButton: true,
                // ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
    );
  }
}
