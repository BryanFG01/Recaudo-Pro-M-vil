import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: AppStrings.home,
        ),
        // boton de agregar nuevo recaudo - OCULTO PERO NO ELIMINADO
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.add_outlined),
        //   activeIcon: Icon(Icons.add),
        //   label: AppStrings.newCollection,
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: AppStrings.reports,
        ),
      ],
      onTap: (index) {
        if (index == 0) {
          // Navegar al dashboard
          context.go('/dashboard');
        } else if (index == 1) {
          // Navegar a reportes
          context.go('/statistics');
        }
      },
    );
  }
}
