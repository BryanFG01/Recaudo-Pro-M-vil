import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/business_helper.dart';
import '../../../domain/entities/client_entity.dart';
import '../../../domain/entities/credit_entity.dart';
import '../../providers/client_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

const _uuid = Uuid();

class NewClientScreen extends ConsumerStatefulWidget {
  const NewClientScreen({super.key});

  @override
  ConsumerState<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends ConsumerState<NewClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentIdController = TextEditingController();

  // Credit fields
  final _creditAmountController = TextEditingController();
  final _interestController = TextEditingController(text: '20');
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // Location fields
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  bool _isLoading = false;

  // Calculate daily installment based on amount, dates, and interest
  double _calculateDailyInstallment() {
    if (_creditAmountController.text.trim().isEmpty) return 0;
    
    final creditAmount = double.tryParse(_creditAmountController.text.trim()) ?? 0;
    if (creditAmount <= 0) return 0;

    final interest = double.tryParse(_interestController.text.trim()) ?? 0;
    final daysDifference = _endDate.difference(_startDate).inDays;
    
    if (daysDifference <= 0) return 0;

    // Calculate: Interés = Monto × Tasa / 100
    final interestAmount = creditAmount * interest / 100;
    // Total a pagar = Monto + Interés
    final totalToPay = creditAmount + interestAmount;
    // Cuota diaria = Total a pagar ÷ Días totales
    final dailyInstallment = totalToPay / daysDifference;

    return dailyInstallment;
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to recalculate daily installment when values change
    _creditAmountController.addListener(() {
      setState(() {});
    });
    _interestController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _documentIdController.dispose();
    _creditAmountController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              background: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _captureCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor activa el servicio de ubicación'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permisos de ubicación denegados'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Los permisos de ubicación están denegados permanentemente'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación capturada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar ubicación: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _handleSaveClientAndCredit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final createCreditUseCase = ref.read(createCreditUseCaseProvider);
      final clientRepository = ref.read(clientRepositoryProvider);

      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      // Create client with UUID
      final clientId = _uuid.v4();
      final client = ClientEntity(
        id: clientId,
        name: fullName,
        phone: _phoneController.text.trim(),
        documentId: _documentIdController.text.trim().isEmpty
            ? null
            : _documentIdController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        createdAt: DateTime.now(),
      );

      // Obtener business_id del negocio seleccionado
      final businessId = BusinessHelper.getCurrentBusinessIdOrThrow(ref);
      
      // Crear cliente con business_id
      await clientRepository.createClient(client, businessId: businessId);

      // Create credit if amount is provided
      if (_creditAmountController.text.trim().isNotEmpty) {
        final creditAmount =
            double.tryParse(_creditAmountController.text.trim()) ?? 0;
        if (creditAmount > 0) {
          final interest =
              double.tryParse(_interestController.text.trim()) ?? 0;
          
          // Calculate: Interés = Monto × Tasa / 100
          final interestAmount = creditAmount * interest / 100;
          // Total a pagar = Monto + Interés
          final totalWithInterest = creditAmount + interestAmount;

          // Calculate daily installment
          final daysDifference = _endDate.difference(_startDate).inDays;
          if (daysDifference <= 0) {
            throw Exception('La fecha final debe ser posterior a la fecha de inicio');
          }
          
          // Cuota diaria = Total a pagar ÷ Días totales
          final dailyInstallment = totalWithInterest / daysDifference;

          final credit = CreditEntity(
            id: _uuid.v4(),
            clientId: clientId,
            totalAmount: totalWithInterest,
            installmentAmount: dailyInstallment, // Cuota diaria
            totalInstallments: daysDifference, // Total de días
            paidInstallments: 0,
            overdueInstallments: 0,
            totalBalance: totalWithInterest,
            lastPaymentAmount: 0,
            lastPaymentDate: null,
            createdAt: _startDate,
            nextDueDate: _startDate.add(const Duration(days: 1)), // Próximo pago al día siguiente
          );

          await createCreditUseCase(credit, businessId: businessId);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.clientAndCreditCreated),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh clients and credits lists
        ref.invalidate(clientsProvider);
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
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dailyInstallment = _calculateDailyInstallment();
    final daysDifference = _endDate.difference(_startDate).inDays;

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
          AppStrings.createNewClient,
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
              // First Name
              CustomTextField(
                label: AppStrings.firstName,
                hint: AppStrings.enterFirstName,
                prefixIcon: Icons.person_outline,
                controller: _firstNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Last Name
              CustomTextField(
                label: AppStrings.lastName,
                hint: AppStrings.enterLastName,
                prefixIcon: Icons.person_outline,
                controller: _lastNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone
              CustomTextField(
                label: AppStrings.phone,
                hint: AppStrings.enterPhone,
                prefixIcon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Address
              CustomTextField(
                label: AppStrings.address,
                hint: AppStrings.enterAddress,
                prefixIcon: Icons.location_on_outlined,
                controller: _addressController,
              ),
              const SizedBox(height: 8),
              // Capture Location Button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingLocation
                          ? null
                          : _captureCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(
                        _latitude != null && _longitude != null
                            ? 'Ubicación capturada'
                            : 'Capturar ubicación actual',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _latitude != null && _longitude != null
                            ? AppColors.success
                            : AppColors.primary,
                        side: BorderSide(
                          color: _latitude != null && _longitude != null
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Email (Optional)
              CustomTextField(
                label: AppStrings.emailOptional,
                hint: AppStrings.enterEmail2,
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Document ID (Optional)
              CustomTextField(
                label: AppStrings.documentIdOptional,
                hint: AppStrings.enterDocumentId,
                prefixIcon: Icons.badge_outlined,
                controller: _documentIdController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Credit Details Section
              const Text(
                AppStrings.creditDetails,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Credit Amount
              CustomTextField(
                label: AppStrings.creditAmount,
                hint: AppStrings.enterCreditAmount,
                prefixIcon: Icons.attach_money,
                controller: _creditAmountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.startDate,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateFormatter.format(_startDate),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.endDate,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateFormatter.format(_endDate),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interest
              CustomTextField(
                label: AppStrings.interest,
                hint: '20',
                prefixIcon: Icons.percent,
                controller: _interestController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Calculated Daily Installment Display
              if (_creditAmountController.text.trim().isNotEmpty && daysDifference > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.calculatedDailyInstallment,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            currencyFormatter.format(dailyInstallment),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppStrings.totalDays}: $daysDifference días',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: AppStrings.saveClientAndCredit,
                onPressed: _handleSaveClientAndCredit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
