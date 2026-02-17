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
import '../../../domain/entities/business_entity.dart';
import '../../../domain/entities/client_entity.dart';
import '../../../domain/entities/credit_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/cash_session_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

const _uuid = Uuid();

class NewClientScreen extends ConsumerStatefulWidget {
  final String? clientId;
  final bool isRenovation;

  const NewClientScreen({super.key, this.clientId, this.isRenovation = false});

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
  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).add(const Duration(days: 30));

  // Location fields
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Document photo (captura)
  File? _capturedDocumentFile;
  bool _isCapturingDocument = false;

  bool _isLoading = false;
  // Almacena el ID temporal si se crea el cliente pero falla algo después (crédito, etc)
  // para evitar crear duplicados al reintentar.
  String? _tempClientId;

  ClientEntity? _existingClient;
  CreditEntity? _existingCredit;

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
    final cleanedAmount = _creditAmountController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
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

    if (widget.clientId != null) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final client = await ref
          .read(clientRepositoryProvider)
          .getClientById(widget.clientId!);
      if (client != null) {
        _existingClient = client;
        final names = client.name.split(' ');
        if (names.length >= 2) {
          _firstNameController.text = names[0];
          _lastNameController.text = names.sublist(1).join(' ');
        } else {
          _firstNameController.text = client.name;
        }
        _phoneController.text = client.phone;
        _addressController.text = client.address ?? '';
        _documentIdController.text = client.documentId ?? '';
        _latitude = client.latitude;
        _longitude = client.longitude;

        // Fetch latest credit
        final businessId = BusinessHelper.getCurrentBusinessIdOrThrow(ref);
        final credits = await ref
            .read(creditRepositoryProvider)
            .getCreditsByClientId(businessId, client.id);
        if (credits.isNotEmpty) {
          // Sort by creation date or just take the first one (active one)
          _existingCredit = credits.first;
          _creditAmountController.text = NumberFormat(
            '#,###',
          ).format(_existingCredit!.totalAmount.toInt());
          _interestController.text =
              _existingCredit!.interestRate?.toString() ?? '20';
          _startDate = _existingCredit!.createdAt;
          // Calculate end date based on installments or use existing if available
          // For now, keep the defaults or use credit's next due date related logic
        }
      }
    } catch (e) {
      debugPrint('Error loading existing client: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surface(context),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
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
                'Los permisos de ubicación están denegados permanentemente',
              ),
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
      if (currentUser == null) {
        throw Exception('Usuario no disponible. Vuelve a iniciar sesión.');
      }
      // Si no hay negocio seleccionado (p. ej. tras esperar en la vista), usar el del usuario actual
      BusinessEntity? business = selectedBusiness;
      if (business == null) {
        business = await ref
            .read(businessRepositoryProvider)
            .getBusinessById(currentUser.businessId);
      }
      if (business == null) {
        throw Exception(
          'Negocio no disponible. Selecciona un negocio o vuelve a entrar.',
        );
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
                  'La foto no pudo asociarse al cliente. Cliente se creará sin foto del documento.',
                ),
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
                  'Error al subir la foto: ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : e}',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          documentFileUrl = null;
        }
      }

      final userNumber =
          currentUser.number ?? currentUser.employeeCode ?? currentUser.id;

      ClientEntity finalClient;
      // Si ya tenemos un ID (edición/renovación) O si acabamos de crear uno (pero falló algo después)
      if (widget.clientId != null || _tempClientId != null) {
        // En modo edición o renovación, SIEMPRE usar update del cliente
        // O si ya se creó parcialmente (_tempClientId)
        final effectiveId = widget.clientId ?? _tempClientId!;
        debugPrint('Updating client with ID: $effectiveId');

        final clientToUpdate = _existingClient ??
            ClientEntity(
              id: effectiveId,
              name: fullName,
              phone: _phoneController.text.trim(),
              createdAt: DateTime.now(),
            );

        final updatedClient = clientToUpdate.copyWith(
          name: fullName,
          phone: _phoneController.text.trim(),
          documentId: _documentIdController.text.trim().isEmpty
              ? null
              : _documentIdController.text.trim(),
          documentFileUrl: documentFileUrl ?? _existingClient?.documentFileUrl,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
        if (widget.isRenovation) {
          // Renovación: crear nueva versión del cliente preservando el original
          finalClient = await clientRepository.versionClient(
            updatedClient,
            businessId: businessId,
            businessCode: business.code,
            userId: currentUser.id,
            userNumber: userNumber,
          );
          debugPrint('Client versioned successfully. New ID: ${finalClient.id}');
        } else {
          finalClient = await clientRepository.updateClient(updatedClient);
          debugPrint('Client updated successfully. ID: ${finalClient.id}');
        }
      } else {
        // Create client with UUID
        final client = ClientEntity(
          id: _uuid.v4(),
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

        finalClient = await clientRepository.createClient(
          client,
          businessId: businessId,
          businessCode: business.code,
          userId: currentUser.id,
          userNumber: userNumber,
        );
        // Guardar ID temporalmente por si falla algo después (crédito, imagen, etc)
        // para que al reintentar se use update en vez de create.
        _tempClientId = finalClient.id;
      }

      if (_creditAmountController.text.trim().isNotEmpty) {
        final cleanedAmount = _creditAmountController.text.replaceAll(
          RegExp(r'[^\d]'),
          '',
        );
        final creditAmount = double.tryParse(cleanedAmount) ?? 0;
        if (creditAmount > 0) {
          final interest =
              double.tryParse(_interestController.text.trim()) ?? 0;
          final interestAmount = creditAmount * interest / 100;
          final totalWithInterest = creditAmount + interestAmount;

          final workingDays = _calculateWorkingDays(_startDate, _endDate);
          if (workingDays <= 0) {
            throw Exception(
              'El rango de fechas debe incluir al menos un día hábil (lunes a sábado)',
            );
          }

          final dailyInstallment = totalWithInterest / workingDays;

          // Si hay un cliente existente, intentamos actualizar el crédito (Renovación)
          if (widget.clientId != null && widget.isRenovation) {
            debugPrint('Renovation mode (isRenovation=true): Looking for existing credit for client ${widget.clientId}');
            // Si no tenemos el crédito en memoria, intentamos buscarlo una última vez
            if (_existingCredit == null) {
              final credits = await ref
                  .read(creditRepositoryProvider)
                  .getCreditsByClientId(businessId, widget.clientId!);
              debugPrint('Found ${credits.length} credits for client ${widget.clientId}');
              if (credits.isNotEmpty) {
                _existingCredit = credits.first;
                debugPrint('Using existing credit ID: ${_existingCredit!.id}');
              } else {
                debugPrint('WARNING: No existing credit found for renovation!');
              }
            }

            if (_existingCredit != null) {
              final activeSession = await ref.read(
                cashSessionByUserProvider(currentUser.id).future,
              );

              final updatedCredit = _existingCredit!.copyWith(
                totalAmount: creditAmount,
                installmentAmount: dailyInstallment,
                totalInstallments: workingDays,
                totalBalance: totalWithInterest,
                interestRate: interest,
                totalInterest: interestAmount,
                createdAt: _startDate,
                nextDueDate: _startDate.add(const Duration(days: 1)),
                cashSessionId: activeSession?.id,
              );

              debugPrint('Renovating Credit (Update): ${updatedCredit.id}');
              await ref.read(creditRepositoryProvider).updateCredit(
                    updatedCredit,
                    businessId: businessId,
                    userNumber: userNumber,
                    documentId: finalClient.documentId,
                  );
            } else {
              // Si de verdad NO hay crédito previo, entonces creamos uno nuevo para este cliente existente
              debugPrint(
                'No existing credit found for renovation, creating new one for client ${finalClient.id}',
              );
              debugPrint(
                'WARNING: Creating credit with client_id: ${finalClient.id} (original widget.clientId: ${widget.clientId})',
              );

              // Verificar que el cliente existe antes de crear el crédito
              final clientExists = await ref
                  .read(clientRepositoryProvider)
                  .getClientById(finalClient.id);
              if (clientExists == null) {
                throw Exception(
                  'El cliente ${finalClient.id} no existe en el backend. '
                  'Puede haber un problema de sincronización. Intenta refrescar la lista de clientes.',
                );
              }
              debugPrint('Client verified to exist before creating credit: ${clientExists.id}');

              final credit = CreditEntity(
                id: _uuid.v4(),
                clientId: finalClient.id,
                totalAmount: creditAmount,
                installmentAmount: dailyInstallment,
                totalInstallments: workingDays,
                paidInstallments: 0,
                overdueInstallments: 0,
                totalBalance: totalWithInterest,
                lastPaymentAmount: 0,
                lastPaymentDate: null,
                createdAt: _startDate,
                nextDueDate: _startDate.add(const Duration(days: 1)),
                interestRate: interest,
                totalInterest: interestAmount,
              );

              final activeSession = await ref.read(
                cashSessionByUserProvider(currentUser.id).future,
              );

              await createCreditUseCase(
                credit,
                businessId: businessId,
                businessCode: business.code,
                userNumber: userNumber,
                documentId: finalClient.documentId,
                cashSessionId: activeSession?.id,
              );
            }
          } else {
            // Flujo normal de creación (Cliente y Crédito completamente nuevos)
            final credit = CreditEntity(
              id: _uuid.v4(),
              clientId: finalClient.id,
              totalAmount: creditAmount,
              installmentAmount: dailyInstallment,
              totalInstallments: workingDays,
              paidInstallments: 0,
              overdueInstallments: 0,
              totalBalance: totalWithInterest,
              lastPaymentAmount: 0,
              lastPaymentDate: null,
              createdAt: _startDate,
              nextDueDate: _startDate.add(const Duration(days: 1)),
              interestRate: interest,
              totalInterest: interestAmount,
            );

            final activeSession = await ref.read(
              cashSessionByUserProvider(currentUser.id).future,
            );

            await createCreditUseCase(
              credit,
              businessId: businessId,
              businessCode: business.code,
              userNumber: userNumber,
              documentId: finalClient.documentId,
              cashSessionId: activeSession?.id,
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.clientId != null
                  ? 'Cliente y crédito actualizados'
                  : AppStrings.clientAndCreditCreated,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh clients and credits lists; ventas y recaudo para Sesión de Caja
        ref.invalidate(clientsProvider);
        ref.invalidate(creditsProvider);
        ref.invalidate(
          totalVentasHoyProvider((
            businessId: currentUser.businessId,
            userId: currentUser.id,
          )),
        );
        ref.invalidate(
          totalRecaudoRealProvider((
            businessId: currentUser.businessId,
            userId: currentUser.id,
          )),
        );
        // Refrescar flow de sesión de caja para que total_credits incluya este crédito
        final session = await ref.read(
          cashSessionByUserProvider(currentUser.id).future,
        );
        if (session?.id != null && session!.id.isNotEmpty) {
          ref.invalidate(cashSessionFlowProvider(session.id));
          ref.invalidate(
            totalVentasPorSesionProvider((
              businessId: currentUser.businessId,
              userId: currentUser.id,
              sessionId: session.id,
            )),
          );
        }
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
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final dailyInstallment = _calculateDailyInstallment();
    final workingDays = _calculateWorkingDays(_startDate, _endDate);

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
          widget.clientId != null
              ? (widget.isRenovation ? 'Renovar Cliente' : 'Editar Cliente')
              : AppStrings.createNewClient,
          style: TextStyle(
            color: AppColors.textPrimary(context),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
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
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: AppColors.surface(context),
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
              Text(
                AppStrings.creditDetails,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
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
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _creditAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: AppStrings.enterCreditAmount,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary(context),
                      ),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: AppColors.textSecondary(context),
                      ),
                      filled: true,
                      fillColor: AppColors.surface(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.textSecondary(
                            context,
                          ).withOpacity(0.3),
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
                        Text(
                          AppStrings.startDate,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
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
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: AppColors.textSecondary(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateFormatter.format(_startDate),
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
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
                        Text(
                          AppStrings.endDate,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
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
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: AppColors.textSecondary(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateFormatter.format(_endDate),
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
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
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.calculatedDailyInstallment,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
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
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: widget.clientId != null
                    ? (widget.isRenovation ? 'Renovar' : 'Actualizar')
                    : AppStrings.saveClientAndCredit,
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
