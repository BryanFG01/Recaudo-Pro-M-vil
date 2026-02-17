import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/expense_categories.dart';
import '../../../core/utils/thousands_separator_input_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cash_session_provider.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Módulo de gastos: solo registro. La lista de gastos se ve en Reportes > Ver reporte de gastos.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  /// Valor del dropdown: id de la categoría (String) para evitar error de tipo con restauración de estado.
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión de usuario no encontrada'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Obtener sesión de caja activa para el retiro
    final cashSession =
        ref.read(cashSessionByUserProvider(user.id)).valueOrNull;
    if (cashSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No hay una sesión de caja activa para registrar el gasto'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final amount =
        ThousandsSeparatorInputFormatter.parse(_amountController.text.trim()) ??
            0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un monto válido'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final category = _findCategory(_selectedCategoryId);
      final categoryName = category?.name ?? 'General';
      final reasonText = _reasonController.text.trim();
      // Concatenamos categoría en el motivo para que el admin lo identifique en retiros
      final finalReason = reasonText.isEmpty
          ? '[GASTO] $categoryName'
          : '[GASTO] $categoryName: $reasonText';

      final useCase = ref.read(createWithdrawalUseCaseProvider);
      await useCase(
        cashSessionId: cashSession.id,
        userId: user.id,
        amount: amount.toDouble(),
        reason: finalReason,
        isApproved: false,
      );

      _amountController.clear();
      _reasonController.clear();

      // Invalidar proveedores para refrescar datos en Caja y Reportes
      ref.invalidate(withdrawalsByUserProvider(user.id));
      ref.invalidate(cashSessionFlowProvider(cashSession.id));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedCategoryId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.expenseRegistered),
            backgroundColor: AppColors.success,
          ),
        );
        // Volver atrás para ver el balance actualizado
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar gasto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Valor solo si existe en la lista (evita crash si el estado restaurado no coincide).
  String? get _safeDropdownValue {
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)
      return null;
    final validIds = expenseCategories.map((c) => c.id).toSet();
    return validIds.contains(_selectedCategoryId) ? _selectedCategoryId : null;
  }

  ExpenseCategory? _findCategory(String? id) {
    if (id == null) return null;
    for (final c in expenseCategories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Selector de categoría que se despliega hacia abajo con señal de más opciones al hacer scroll.
  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary(ctx).withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecciona una categoría',
                style: TextStyle(
                  color: AppColors.textPrimary(ctx),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: expenseCategories.length,
                itemBuilder: (context, index) {
                  final cat = expenseCategories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCategoryId = cat.id);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cat.icon,
                              size: 22,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Señal de flecha: hay más opciones al hacer scroll
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface(ctx),
                border: Border(
                  top: BorderSide(
                    color: AppColors.textSecondary(ctx).withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 28,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Desliza para ver más opciones',
                    style: TextStyle(
                      color: AppColors.textSecondary(ctx),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          AppStrings.registerExpense,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline,
                color: AppColors.textSecondary(context)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  AppStrings.expenseInfoMessage,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: AppStrings.expenseAmount,
                hint: '\$ 0.00',
                controller: _amountController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese el monto';
                  final n = ThousandsSeparatorInputFormatter.parse(v);
                  if (n == null || n <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // CustomTextField(
              //   label: AppStrings.expenseReason,
              //   hint: AppStrings.expenseReasonHint,
              //   controller: _reasonController,
              //   prefixIcon: Icons.description_outlined,
              //   validator: (v) {
              //     if (v == null || v.trim().isEmpty)
              //       return 'Ingrese el motivo del gasto';
              //     return null;
              //   },
              // ),
              const SizedBox(height: 20),
              Text(
                AppStrings.category,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showCategoryPicker(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _findCategory(_safeDropdownValue)?.icon ??
                            Icons.category_outlined,
                        size: 22,
                        color: _findCategory(_safeDropdownValue) != null
                            ? AppColors.primary
                            : AppColors.textSecondary(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _findCategory(_safeDropdownValue)?.name ??
                              'Selecciona una categoría',
                          style: TextStyle(
                            color: _findCategory(_safeDropdownValue) != null
                                ? AppColors.textPrimary(context)
                                : AppColors.textSecondary(context),
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: AppStrings.registerExpense,
                onPressed: _isLoading ? null : _submitExpense,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }
}
