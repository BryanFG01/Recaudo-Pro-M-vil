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

  static const _routes = ['/dashboard', '/statistics'];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider(context), width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.surface(context),
        selectedItemColor: AppColors.textPrimary(context),
        unselectedItemColor: AppColors.textSecondary(context),
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: AppStrings.reports,
          ),
        ],
        onTap: (index) => context.go(_routes[index]),
      ),
    );
  }
}
