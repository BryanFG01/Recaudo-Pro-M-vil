import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/business_helper.dart';
import '../../../domain/entities/client_entity.dart';
import '../../../domain/entities/credit_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
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

  // Document photo (captura)
  File? _capturedDocumentFile;
  bool _isCapturingDocument = false;

  bool _isLoading = false;

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _takeDocumentPhoto() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.cameraNotAvailableOnWeb),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() => _isCapturingDocument = true);
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (photo != null && mounted) {
        setState(() {
          _capturedDocumentFile = File(photo.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.documentPhotoCaptured),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } on MissingPluginException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.cameraPluginNotLinked),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturingDocument = false);
      }
    }
  }

  // Formatear el monto de crédito con separadores de miles
  void _formatCreditAmount() {
    final text = _creditAmountController.text;
    final selection = _creditAmountController.selection;

    // Remover todas las comas y caracteres no numéricos
    final cleanedText = text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedText.isEmpty) {
      if (text.isNotEmpty) {
        // Si hay texto pero no números, limpiar
        _creditAmountController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      return;
    }

    // Convertir a número
    final number = int.tryParse(cleanedText);
    if (number == null) {
      return;
    }

    // Formatear con separadores de miles
    final formatted = NumberFormat('#,###').format(number);

    // Calcular nueva posición del cursor
    final oldLength = text.length;
    final newLength = formatted.length;
    final cursorOffset = selection.baseOffset;
    final newCursorPosition = cursorOffset + (newLength - oldLength);

    // Actualizar el texto formateado manteniendo la posición del cursor
    if (formatted != text) {
      _creditAmountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: newCursorPosition.clamp(0, formatted.length),
        ),
      );
    }
  }

  // Calculate number of days excluding Sundays
  int _calculateWorkingDays(DateTime start, DateTime end) {
    int count = 0;
    // Normalize to midnight to ensure accurate day counting
    DateTime current = DateTime(start.year, start.month, start.day);
    final DateTime endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      if (current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  // Calculate daily installment based on amount, dates, and interest
  double _calculateDailyInstallment() {
    if (_creditAmountController.text.trim().isEmpty) return 0;

    // Limpiar formato: quitar comas, puntos y todo lo no numérico (500.000 / 500,000 → 500000)
    final cleanedAmount =
        _creditAmountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final creditAmount = double.tryParse(cleanedAmount) ?? 0;
    if (creditAmount <= 0) return 0;

    final interest = double.tryParse(_interestController.text.trim()) ?? 0;

    // Usar días hábiles (excluyendo domingos)
    final workingDays = _calculateWorkingDays(_startDate, _endDate);

    if (workingDays <= 0) return 0;

    // Interés = Monto × Tasa / 100. Total a pagar = Monto + Interés
    final interestAmount = creditAmount * interest / 100;
    final totalToPay = creditAmount + interestAmount;
    // Cuota diaria = Total a pagar ÷ Días totales (hábiles)
    final dailyInstallment = totalToPay / workingDays;

    return dailyInstallment;
  }

  @override
  void initState() {
    super.initState();
    // Agregar listener para formatear el monto con separadores de miles
    _creditAmountController.addListener(_formatCreditAmount);
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
    _creditAmountController.removeListener(_formatCreditAmount);
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
          if (_endDate.isBefore(_startDate) ||
              _endDate.isAtSameMomentAs(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate) ||
              _endDate.isAtSameMomentAs(_startDate)) {
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

    // Cerrar teclado para evitar IME/animation y que se vea el SnackBar
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final createCreditUseCase = ref.read(createCreditUseCaseProvider);
      final clientRepository = ref.read(clientRepositoryProvider);

      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      final businessId = BusinessHelper.getCurrentBusinessIdOrThrow(ref);
      final selectedBusiness = ref.read(selectedBusinessProvider);
      final currentUser = ref.read(currentUserProvider);
      if (selectedBusiness == null || currentUser == null) {
        throw Exception('Negocio o usuario no disponible');
      }

      // Subir foto del documento si se capturó; obtener URL para document_file_url
      String? documentFileUrl;
      if (_capturedDocumentFile != null) {
        try {
          documentFileUrl = await clientRepository.uploadDocumentFile(
            _capturedDocumentFile!,
            businessId: businessId,
          );
          if (documentFileUrl == null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'La foto no pudo asociarse al cliente. Cliente se creará sin foto del documento.'),
                backgroundColor: AppColors.warning,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error al subir la foto: ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : e}'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          documentFileUrl = null;
        }
      }

      // Create client with UUID
      final clientId = _uuid.v4();
      final client = ClientEntity(
        id: clientId,
        name: fullName,
        phone: _phoneController.text.trim(),
        documentId: _documentIdController.text.trim().isEmpty
            ? null
            : _documentIdController.text.trim(),
        documentFileUrl: documentFileUrl,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        createdAt: DateTime.now(),
      );

      final userNumber =
          currentUser.number ?? currentUser.employeeCode ?? currentUser.id;
      await clientRepository.createClient(
        client,
        businessId: businessId,
        businessCode: selectedBusiness.code,
        userId: currentUser.id,
        userNumber: userNumber,
      );

      if (_creditAmountController.text.trim().isNotEmpty) {
        // Limpiar formato: quitar comas, puntos y todo lo no numérico (500.000 / 500,000 → 500000)
        final cleanedAmount =
            _creditAmountController.text.replaceAll(RegExp(r'[^\d]'), '');
        final creditAmount = double.tryParse(cleanedAmount) ?? 0;
        if (creditAmount > 0) {
          final interest =
              double.tryParse(_interestController.text.trim()) ?? 0;

          // Interés = Monto × Tasa / 100. Total a pagar = Principal + Interés
          final interestAmount = creditAmount * interest / 100;
          final totalWithInterest = creditAmount + interestAmount;

          final workingDays = _calculateWorkingDays(_startDate, _endDate);
          if (workingDays <= 0) {
            throw Exception(
                'El rango de fechas debe incluir al menos un día hábil (lunes a sábado)');
          }

          // Cuota diaria = Total a pagar ÷ Días totales (hábiles)
          final dailyInstallment = totalWithInterest / workingDays;

          // API: total_amount = principal (monto del préstamo), total_interest = monto del interés.
          // total_balance y cuotas se basan en el total a pagar (principal + interés).
          final credit = CreditEntity(
            id: _uuid.v4(),
            clientId: clientId,
            totalAmount: creditAmount, // principal
            installmentAmount: dailyInstallment,
            totalInstallments: workingDays,
            paidInstallments: 0,
            overdueInstallments: 0,
            totalBalance:
                totalWithInterest, // total a pagar (principal + interés)
            lastPaymentAmount: 0,
            lastPaymentDate: null,
            createdAt: _startDate,
            nextDueDate: _startDate.add(const Duration(days: 1)),
            interestRate: interest,
            totalInterest: interestAmount,
          );

          await createCreditUseCase(
            credit,
            businessId: businessId,
            businessCode: selectedBusiness.code,
            userNumber: userNumber,
            documentId: client.documentId,
          );
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
    } catch (e, st) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        final msg = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $msg'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
        debugPrint('Error guardar cliente: $e\n$st');
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
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dailyInstallment = _calculateDailyInstallment();
    final workingDays = _calculateWorkingDays(_startDate, _endDate);

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
                      onPressed:
                          _isLoadingLocation ? null : _captureCurrentLocation,
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
              const SizedBox(height: 20),
              // Tomar foto del documento
              Text(
                AppStrings.takeDocumentPhoto,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isCapturingDocument ? null : _takeDocumentPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isCapturingDocument)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Text(
                          _isCapturingDocument
                              ? 'Capturando...'
                              : AppStrings.takeDocumentPhoto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_capturedDocumentFile != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.file(
                        _capturedDocumentFile!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.creditAmount,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _creditAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppStrings.enterCreditAmount,
                      hintStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
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
              if (_creditAmountController.text.trim().isNotEmpty &&
                  workingDays > 0)
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
                        '${AppStrings.totalDays}: $workingDays días (sin domingos)',
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
