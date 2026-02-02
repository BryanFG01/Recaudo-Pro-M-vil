import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/business_helper.dart';
import '../../../domain/entities/client_entity.dart';
import '../../../domain/entities/collection_entity.dart';
import '../../../domain/entities/credit_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

const _uuid = Uuid();

class NewCollectionScreen extends ConsumerStatefulWidget {
  const NewCollectionScreen({super.key});

  @override
  ConsumerState<NewCollectionScreen> createState() =>
      _NewCollectionScreenState();
}

class _NewCollectionScreenState extends ConsumerState<NewCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  ClientEntity? _selectedClient;
  String _selectedPaymentType = 'regular'; // 'regular' or 'extra'
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _showClientSelector() async {
    final clientsAsync = ref.read(clientsProvider);

    await clientsAsync.when(
      data: (clients) async {
        if (clients.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hay clientes disponibles. Crea uno primero.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }

        final selected = await showModalBottomSheet<ClientEntity>(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.selectClient,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            client.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          client.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          client.phone,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        onTap: () => Navigator.pop(context, client),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        if (selected != null) {
          setState(() => _selectedClient = selected);
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cargando clientes...')),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  Future<void> _handleSaveCollection() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.pleaseSelectClient),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      final businessId = BusinessHelper.getCurrentBusinessIdOrThrow(ref);
      final creditRepository = ref.read(creditRepositoryProvider);
      final credits =
          await creditRepository.getCreditsByClientId(businessId, _selectedClient!.id);

      if (credits.isEmpty) {
        throw Exception('El cliente no tiene créditos activos');
      }

      final credit = credits.first;
      final amount = double.tryParse(_amountController.text.trim()) ?? 0;

      if (amount <= 0) {
        throw Exception(AppStrings.pleaseEnterAmount);
      }

      // Obtener el crédito actualizado desde la base de datos
      final currentCredit = await creditRepository.getCreditById(credit.id);
      if (currentCredit == null) {
        throw Exception('No se encontró el crédito en la base de datos');
      }

      // Calcular el nuevo saldo
      final newTotalBalance = currentCredit.totalBalance - amount;

      final createCollectionUseCase = ref.read(createCollectionUseCaseProvider);
      final collection = CollectionEntity(
        id: _uuid.v4(),
        creditId: credit.id,
        clientId: _selectedClient!.id,
        amount: amount,
        paymentDate: DateTime.now(),
        userId: currentUser.id,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await createCollectionUseCase(collection, businessId: businessId);

      // Actualizar el crédito: disminuir el totalBalance
      final updatedCredit = CreditEntity(
        id: currentCredit.id,
        clientId: currentCredit.clientId,
        totalAmount: currentCredit.totalAmount,
        installmentAmount: currentCredit.installmentAmount,
        totalInstallments: currentCredit.totalInstallments,
        paidInstallments: currentCredit.paidInstallments + 1,
        overdueInstallments: currentCredit.overdueInstallments,
        totalBalance: newTotalBalance < 0 ? 0 : newTotalBalance,
        lastPaymentAmount: amount,
        lastPaymentDate: DateTime.now(),
        createdAt: currentCredit.createdAt,
        nextDueDate: currentCredit.nextDueDate,
        interestRate: currentCredit.interestRate,
        totalInterest: currentCredit.totalInterest,
      );

      // Actualizar el crédito en la base de datos
      await creditRepository.updateCredit(updatedCredit,
          businessId: businessId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.collectionSavedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh data
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(recentCollectionsProvider);
        ref.invalidate(creditsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          AppStrings.newCollectionTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Client Selection
              const Text(
                AppStrings.client,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showClientSelector,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: _selectedClient != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedClient?.name ?? AppStrings.selectClient,
                          style: TextStyle(
                            color: _selectedClient != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Amount
              CustomTextField(
                label: AppStrings.amountToCollect,
                hint: '\$ 0.00',
                prefixIcon: Icons.attach_money,
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un monto';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Payment Type
              const Text(
                AppStrings.collectionType,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentTypeButton(
                      'regular',
                      AppStrings.regularPayment,
                      Icons.payment_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPaymentTypeButton(
                      'extra',
                      AppStrings.extraPayment,
                      Icons.add_card_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Notes
              CustomTextField(
                label: AppStrings.notes,
                hint: AppStrings.addNote,
                prefixIcon: Icons.note_outlined,
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              // Save Button
              CustomButton(
                text: AppStrings.saveCollection,
                onPressed: _handleSaveCollection,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeButton(String type, String label, IconData icon) {
    final isSelected = _selectedPaymentType == type;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
