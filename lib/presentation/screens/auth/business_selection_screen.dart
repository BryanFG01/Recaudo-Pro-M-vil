import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/business_entity.dart';
import '../../providers/business_provider.dart';
import '../../widgets/custom_button.dart';

class BusinessSelectionScreen extends ConsumerStatefulWidget {
  const BusinessSelectionScreen({super.key});

  @override
  ConsumerState<BusinessSelectionScreen> createState() =>
      _BusinessSelectionScreenState();
}

class _BusinessSelectionScreenState
    extends ConsumerState<BusinessSelectionScreen> {
  final _searchController = TextEditingController();
  BusinessEntity? _selectedBusiness;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleEnter() {
    if (_selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un negocio'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Guardar el negocio seleccionado en el provider
    ref.read(selectedBusinessProvider.notifier).setBusiness(_selectedBusiness!);

    // Navegar al login
    context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(businessesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Help button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  // TODO: Mostrar ayuda
                },
              ),
            ),
            // Logo and App Name
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Name
                    const Text(
                      'RecaudoPro',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Search Label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        AppStrings.searchBusinessByNameOrNumber,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchBusiness,
                          hintStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value.toLowerCase());
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Business List
                    Expanded(
                      child: businessesAsync.when(
                        data: (businesses) {
                          if (businesses.isEmpty) {
                            return const Center(
                              child: Text(
                                'No se encontraron negocios',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          // Filtrar negocios por búsqueda
                          final filteredBusinesses = _searchQuery.isEmpty
                              ? businesses
                              : businesses.where((business) {
                                  return business.name
                                          .toLowerCase()
                                          .contains(_searchQuery) ||
                                      business.code
                                          .toLowerCase()
                                          .contains(_searchQuery);
                                }).toList();

                          if (filteredBusinesses.isEmpty) {
                            return const Center(
                              child: Text(
                                'No se encontraron negocios',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredBusinesses.length,
                            itemBuilder: (context, index) {
                              final business = filteredBusinesses[index];
                              final isSelected =
                                  _selectedBusiness?.id == business.id;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedBusiness = business;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary
                                              .withOpacity(0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            business.code,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              business.name,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (business.description != null)
                                              Text(
                                                business.description!,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white70
                                                      : AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Center(
                          child: Text(
                            'Error: ${error.toString()}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Enter Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomButton(
                        text: AppStrings.enter,
                        onPressed: _handleEnter,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
