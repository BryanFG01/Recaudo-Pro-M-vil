import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider(1));

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
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            // icon de salir de la vista deslogarse
            icon:
                const Icon(Icons.logout_outlined, color: AppColors.textPrimary),
            onPressed: () {
              ref.read(currentUserProvider.notifier).setUser(null);
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Collection Card
            statsAsync.when(
              data: (stats) => StatCard(
                title: AppStrings.dailyCollection,
                amount: stats.dailyCollection,
                subtitle: AppStrings.todaySummary,
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          // boton de agregar nuevo recaudo
          BottomNavigationBarItem(
            icon: Icon(Icons.add_outlined),
            activeIcon: Icon(Icons.add),
            label: AppStrings.newCollection,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: AppStrings.reports,
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.help_outline),
          //   activeIcon: Icon(Icons.help_outline),
          //   label: AppStrings.help,
          // ),
        ],
        onTap: (index) {
          if (index == 1) {
            context.push('/new-collection');
          }
          if (index == 2) {
            context.push('/statistics');
          }
        },
      ),
    );
  }
}
