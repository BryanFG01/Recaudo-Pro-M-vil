import 'package:RecaudoPro/domain/entities/client_entity.dart';
import 'package:RecaudoPro/domain/entities/collection_entity.dart';
import 'package:RecaudoPro/domain/entities/credit_entity.dart';
import 'package:RecaudoPro/domain/entities/credit_summary_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/business_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cash_session_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/print_preview_dialog.dart';

const _uuid = Uuid();

class ClientVisitScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientVisitScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientVisitScreen> createState() => _ClientVisitScreenState();
}

class _ClientVisitScreenState extends ConsumerState<ClientVisitScreen> {
  final _amountController = TextEditingController();
  final _transactionController = TextEditingController();
  String _paymentMethod = 'Efectivo';
  bool _isLoadingPayment = false; // Estado de carga para "Realizar Abono"
  bool _isLoadingFullPayment =
      false; // Estado de carga para "Pagar Cuota Completa"
  String? _creditId;
  int _refreshKey = 0;
  bool _isRefreshing = false;
  List<dynamic>? _cachedData; // Cachear datos para evitar pantalla negra
  CreditSummaryEntity? _creditSummary; // Resumen con total_balance desde API

  @override
  void initState() {
    super.initState();
    // Agregar listener para formatear el monto con separadores de miles
    _amountController.addListener(_formatAmount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatAmount);
    _amountController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  // Formatear el monto con separadores de miles
  void _formatAmount() {
    final text = _amountController.text;
    final selection = _amountController.selection;

    // Remover todas las comas y caracteres no numéricos
    final cleanedText = text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedText.isEmpty) {
      if (text.isNotEmpty) {
        // Si hay texto pero no números, limpiar
        _amountController.value = const TextEditingValue(
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

    // Solo actualizar si el texto formateado es diferente al actual
    if (formatted != text) {
      // Calcular nueva posición del cursor
      final cursorPosition = selection.baseOffset;
      final textBeforeCursor = text.substring(0, cursorPosition);
      final cleanedBeforeCursor =
          textBeforeCursor.replaceAll(RegExp(r'[^\d]'), '');
      final newCursorPosition =
          formatted.length - (cleanedText.length - cleanedBeforeCursor.length);

      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: newCursorPosition.clamp(0, formatted.length),
        ),
      );
    }
  }

  Future<List<dynamic>> _loadClientData() async {
    final businessId = BusinessHelper.getCurrentBusinessIdOrThrow(ref);
    final client =
        await ref.read(clientRepositoryProvider).getClientById(widget.clientId);
    final credits = await ref
        .read(creditRepositoryProvider)
        .getCreditsByClientId(businessId, widget.clientId);

    final credit = credits.isNotEmpty ? credits.first : null;

    final collections = credit != null
        ? await ref
            .read(collectionRepositoryProvider)
            .getCollectionsByCreditId(credit.id, businessId: businessId)
        : <CollectionEntity>[];

    // Resumen del crédito (total_balance, total_paid) desde GET /api/credits/summary/{id}
    CreditSummaryEntity? summary;
    if (credit != null) {
      summary = await ref
          .read(creditRepositoryProvider)
          .getCreditSummaryById(credit.id);
    }

    return [client, credits, collections, summary];
  }

  Future<void> _openNavigationApp(double latitude, double longitude) async {
    try {
      // Intentar abrir Waze primero
      final wazeUri = Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');
      if (await canLaunchUrl(wazeUri)) {
        await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      // Si Waze no está disponible, continuar con Google Maps
    }

    try {
      // Intentar abrir Google Maps app
      final googleMapsUri =
          Uri.parse('google.navigation:q=$latitude,$longitude');
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      // Si la app no está disponible, usar la versión web
    }

    try {
      // Usar Google Maps web como última opción
      final webUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir ninguna aplicación de navegación');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir navegación: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showPaidOffDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppStrings.noOutstandingBalance),
          content: const Text(AppStrings.clientPaidOff),
          actions: <Widget>[
            TextButton(
              child: const Text(AppStrings.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPrintPreview(BuildContext context) async {
    final businessId = BusinessHelper.getCurrentBusinessIdOrThrow(ref);
    final clientRepository = ref.read(clientRepositoryProvider);
    final creditRepository = ref.read(creditRepositoryProvider);
    final collectionRepository = ref.read(collectionRepositoryProvider);

    try {
      final client = await clientRepository.getClientById(widget.clientId);
      final credits = await creditRepository.getCreditsByClientId(
          businessId, widget.clientId);

      if (client == null || credits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar la información para imprimir'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final credit = credits.first;
      final collections = await collectionRepository
          .getCollectionsByCreditId(credit.id, businessId: businessId);

      // Obtener el monto del pago pendiente si hay uno en los campos
      double? pendingAmount;
      String? paymentMethod;
      bool isFullPayment = false;

      if (_amountController.text.isNotEmpty) {
        pendingAmount = double.tryParse(_amountController.text);
        paymentMethod = _paymentMethod;
        isFullPayment = false;
      } else if (_isLoadingFullPayment || _isLoadingPayment) {
        // Si se está procesando un pago, usar el monto de la cuota
        pendingAmount = credit.installmentAmount;
        paymentMethod = _paymentMethod;
        isFullPayment = _isLoadingFullPayment;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => PrintPreviewDialog(
            client: client,
            credit: credit,
            collections: collections,
            pendingPaymentAmount: pendingAmount,
            paymentMethod: paymentMethod,
            isFullPayment: isFullPayment,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al preparar impresión: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openNavigationWithAddress(String address) async {
    // Codificar la dirección para URL
    final encodedAddress = Uri.encodeComponent(address);

    try {
      // Intentar abrir Waze primero con la dirección
      final wazeUri = Uri.parse('waze://?q=$encodedAddress&navigate=yes');
      if (await canLaunchUrl(wazeUri)) {
        await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      // Si Waze no está disponible, continuar con Google Maps
    }

    try {
      // Intentar abrir Google Maps app con la dirección
      final googleMapsUri = Uri.parse('google.navigation:q=$encodedAddress');
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      // Si la app no está disponible, usar la versión web
    }

    try {
      // Usar Google Maps web como última opción
      final webUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir ninguna aplicación de navegación');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir navegación: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handlePayment(bool isFullPayment) async {
    if (!isFullPayment && _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un monto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Actualizar el estado de carga correspondiente
    setState(() {
      if (isFullPayment) {
        _isLoadingFullPayment = true;
      } else {
        _isLoadingPayment = true;
      }
    });

    try {
      final businessId = BusinessHelper.getCurrentBusinessIdOrThrow(ref);
      final clientRepository = ref.read(clientRepositoryProvider);
      final client = await clientRepository.getClientById(widget.clientId);

      if (client == null) {
        throw Exception('Cliente no encontrado');
      }

      final creditRepository = ref.read(creditRepositoryProvider);
      final credits = await creditRepository.getCreditsByClientId(
          businessId, widget.clientId);

      if (credits.isEmpty) {
        throw Exception('No hay créditos para este cliente');
      }

      final credit = credits.first;
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Para cuota completa, usar el monto de la cuota diaria
      // Remover comas del texto antes de convertir a número
      final amountText = _amountController.text.replaceAll(',', '');
      final amount = isFullPayment
          ? credit.installmentAmount
          : double.tryParse(amountText) ?? 0;

      if (amount <= 0) {
        throw Exception('El monto debe ser mayor a cero');
      }

      // Saldo restante desde summary (API) o crédito
      final effectiveBalance = _creditSummary?.totalBalance ?? credit.totalBalance;
      if (amount > effectiveBalance) {
        throw Exception('El monto excede el saldo restante del préstamo');
      }

      // Obtener el crédito desde la base de datos (para id y demás campos)
      final currentCredit = await creditRepository.getCreditById(credit.id);
      if (currentCredit == null) {
        throw Exception('No se encontró el crédito en la base de datos');
      }

      // Calcular el nuevo saldo usando el balance del summary (o del crédito)
      final currentBalance = _creditSummary?.totalBalance ?? currentCredit.totalBalance;
      final newTotalBalance = currentBalance - amount;

      final createCollectionUseCase = ref.read(createCollectionUseCaseProvider);
      final collection = CollectionEntity(
        id: _uuid.v4(),
        creditId: currentCredit.id,
        clientId: widget.clientId,
        amount: amount,
        paymentDate: DateTime.now(),
        userId: currentUser.id,
        paymentMethod: _paymentMethod,
        transactionReference: _paymentMethod == 'Transacción'
            ? _transactionController.text
            : null,
      );

      // Crear la colección (POST /api/collections). El backend calcula
      // total_balance, paid_installments, etc. desde las collections;
      // no se debe llamar a PATCH /api/credits con esos campos.
      await createCollectionUseCase(collection, businessId: businessId);

      // Verificar si el saldo llegó a 0 (según el cálculo local)
      final finalBalance = newTotalBalance < 0 ? 0 : newTotalBalance;
      final isPaidOff = finalBalance == 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago realizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        _amountController.clear();
        _transactionController.clear();
        setState(() {
          _paymentMethod = 'Efectivo';
        });

        // Mostrar alerta si el saldo llegó a 0
        if (isPaidOff && mounted) {
          await _showPaidOffDialog(context);
        }

        // Invalidar los providers para que se actualicen en todas pantallas
        ref.invalidate(creditsProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(recentCollectionsProvider);

        // Invalidar familias completas relacionadas con la sesión de caja para asegurar frescura
        ref.invalidate(cashSessionFlowProvider);
        ref.invalidate(withdrawalsByUserProvider);
        ref.invalidate(cashSessionByUserProvider);
        ref.invalidate(activeCashSessionProvider);

        // Refrescar la vista para mostrar el nuevo recaudo y el saldo actualizado
        if (mounted) {
          setState(() {
            _isRefreshing = true;
            _refreshKey++;
          });
          // Esperar a que se complete la carga antes de ocultar el overlay
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            setState(() {
              _isRefreshing = false;
            });
          }
        }
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
        setState(() {
          if (isFullPayment) {
            _isLoadingFullPayment = false;
          } else {
            _isLoadingPayment = false;
          }
        });
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
          'Visita Cliente y Recaudo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.print_outlined, color: AppColors.textPrimary),
            onPressed: () => _showPrintPreview(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<dynamic>>(
            key: ValueKey(_refreshKey),
            future: _loadClientData(),
            builder: (context, snapshot) {
              // Si hay datos, guardarlos en cache
              if (snapshot.hasData) {
                _cachedData = snapshot.data;
              }

              // Si está cargando y no hay datos en cache, mostrar loading
              if (!snapshot.hasData &&
                  !snapshot.hasError &&
                  _cachedData == null) {
                return const Center(child: CircularProgressIndicator());
              }

              // Si hay un error pero tenemos datos en cache, mostrar los datos en cache
              if (snapshot.hasError && _cachedData != null) {
                // Continuar con los datos en cache
              } else if (snapshot.hasError) {
                // Solo mostrar error si no hay datos en cache
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar datos: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _refreshKey++;
                            _cachedData = null;
                          });
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              // Usar datos actuales o cacheados
              final results = snapshot.hasData ? snapshot.data! : _cachedData!;
              final client = results[0] as ClientEntity?;
              final credits = results[1] as List<CreditEntity>;
              final collections = results[2] as List<CollectionEntity>;
              final summary = results.length > 3
                  ? results[3] as CreditSummaryEntity?
                  : null;

              if (client == null || credits.isEmpty) {
                return const Center(
                  child: Text(
                    'Cliente o crédito no encontrado',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }

              final credit = credits.first;
              if (_creditId == null) {
                _creditId = credit.id;
              }
              // Saldo restante desde API summary (disminuye con cada abono)
              final effectiveBalance =
                  summary?.totalBalance ?? credit.totalBalance;
              if (summary != null && _creditSummary != summary) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _creditSummary = summary);
                });
              }
              final formatter =
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0);
              final dateFormatter = DateFormat('yyyy/MM/dd');

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Name (Large)
                    Text(
                      client.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Client ID and Address
                    if (client.documentId != null)
                      Text(
                        'ID: ${client.documentId!}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    if (client.address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        client.address!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Locate Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (client.latitude != null &&
                                client.longitude != null) {
                              await _openNavigationApp(
                                client.latitude!,
                                client.longitude!,
                              );
                            } else if (client.address != null &&
                                client.address!.isNotEmpty) {
                              // Si no hay coordenadas pero hay dirección, abrir con la dirección
                              await _openNavigationWithAddress(client.address!);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Cliente no tiene ubicación registrada'),
                                    backgroundColor: AppColors.warning,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.location_on, size: 16),
                          label: const Text(AppStrings.locate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Financial Information Boxes
                    Row(
                      children: [
                        // Remaining Loan Amount
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.remainingLoanAmount,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatter.format(effectiveBalance),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${AppStrings.total}: ${formatter.format(credit.totalToPay)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Installment Amount
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppStrings.installmentAmount,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatter.format(credit.installmentAmount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Register Payment Section
                    const Text(
                      AppStrings.registerPayment,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Payment Method Selection
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      dropdownColor:
                          AppColors.surface, // Background for the menu
                      style: const TextStyle(
                          color: AppColors.textPrimary), // Text color for items
                      decoration: InputDecoration(
                        labelText: 'Método de Pago',
                        labelStyle:
                            const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                      items: ['Efectivo', 'Transacción'].map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _paymentMethod = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Transaction Number Input (if applicable)
                    if (_paymentMethod == 'Transacción') ...[
                      CustomTextField(
                        label: 'Número de Comprobante',
                        hint: 'Ingrese el número de transacción',
                        prefixIcon: Icons.receipt,
                        controller: _transactionController,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Payment Amount Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.paymentAmount,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: AppStrings.enterSpecificAmount,
                            hintStyle:
                                const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.attach_money,
                                color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.error, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    CustomButton(
                      text: AppStrings.makePayment,
                      onPressed: (_isLoadingPayment ||
                              _isLoadingFullPayment ||
                              _isRefreshing)
                          ? null
                          : () => _handlePayment(false),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: AppStrings.payFullInstallment,
                      onPressed: (_isLoadingPayment ||
                              _isLoadingFullPayment ||
                              _isRefreshing)
                          ? null
                          : () => _handlePayment(true),
                      backgroundColor: AppColors.success,
                    ),
                    const SizedBox(height: 32),
                    // Collection History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.collectionHistory,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            // TODO: Implementar filtro
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Collections List
                    if (collections.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No hay recaudos registrados',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 300, // Altura fija para habilitar scroll
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: collections.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: AppColors.textSecondary,
                          ),
                          itemBuilder: (context, index) {
                            final collection = collections[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateFormatter
                                              .format(collection.paymentDate),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (collection.paymentMethod !=
                                            null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            collection.paymentMethod!,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatter.format(collection.amount),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          // Overlay de carga mientras se refresca
          if (_isRefreshing || _isLoadingPayment || _isLoadingFullPayment)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
