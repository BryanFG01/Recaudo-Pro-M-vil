import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/client_entity.dart';
import '../../../domain/entities/collection_entity.dart';
import '../../../domain/entities/credit_entity.dart';
import '../../../domain/entities/credit_summary_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class MyWalletScreen extends ConsumerStatefulWidget {
  const MyWalletScreen({super.key});

  @override
  ConsumerState<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends ConsumerState<MyWalletScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isOptimized = false;
  Position? _currentPosition;
  List<dynamic> _sortedCredits = [];
  final Map<String, double> _distances = {};
  // Cache para evitar reconstrucciones innecesarias
  final Map<String, Map<String, dynamic>> _dataCache = {};
  // Datos precargados para mejor rendimiento
  Map<String, Map<String, dynamic>>? _preloadedData;

  // Precargar todos los datos de una vez para mejor rendimiento
  Future<void> _preloadData(List<CreditEntity> credits) async {
    if (_preloadedData != null) return;

    final businessId = ref.read(currentUserProvider)?.businessId;
    if (businessId == null) return;

    final preloaded = <String, Map<String, dynamic>>{};

    final creditRepository = ref.read(creditRepositoryProvider);
    for (final credit in credits) {
      final cacheKey = '${credit.id}_${credit.clientId}';
      if (!preloaded.containsKey(cacheKey)) {
        try {
          final results = await Future.wait<dynamic>([
            ref.read(clientRepositoryProvider).getClientById(credit.clientId),
            ref.read(collectionRepositoryProvider).getCollectionsByCreditId(
                  credit.id,
                  businessId: businessId,
                ),
            creditRepository.getCreditSummaryById(credit.id),
          ]);
          preloaded[cacheKey] = {
            'client': results[0],
            'collections': results[1],
            'summary': results[2],
          };
        } catch (e) {
          // Si hay error, continuar con el siguiente
        }
      }
    }

    if (mounted) {
      setState(() {
        _preloadedData = preloaded;
        _dataCache.addAll(preloaded);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dataCache.clear();
    _preloadedData = null;
    super.dispose();
  }

  // Calcular distancia entre dos coordenadas (en kilómetros)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // Obtener ubicación actual
  Future<void> _getCurrentLocation() async {
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

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Optimizar ruta (ordenar por distancia)
  Future<void> _optimizeRoute(List<dynamic> credits) async {
    if (!_isOptimized) {
      // Obtener ubicación actual
      await _getCurrentLocation();
      if (_currentPosition == null) {
        return;
      }

      // Obtener clientes y calcular distancias
      final creditsWithDistance = await Future.wait(
        credits.map((credit) async {
          try {
            final client = await ref
                .read(clientRepositoryProvider)
                .getClientById(credit.clientId);
            if (client?.latitude != null && client?.longitude != null) {
              final distance = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                client!.latitude!,
                client.longitude!,
              );
              return {'credit': credit, 'distance': distance};
            }
          } catch (e) {
            // Si hay error, usar distancia muy grande
          }
          return {'credit': credit, 'distance': 999999.0};
        }),
      );

      // Ordenar por distancia (más cerca primero)
      creditsWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      _distances.clear();
      for (var item in creditsWithDistance) {
        final credit = item['credit'] as CreditEntity;
        _distances[credit.id] = item['distance'] as double;
      }

      _sortedCredits =
          creditsWithDistance.map((item) => item['credit']).toList();
    } else {
      _sortedCredits = credits;
    }

    setState(() {
      _isOptimized = !_isOptimized;
    });
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditsProvider);

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
          AppStrings.myWallet,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isOptimized ? Icons.route : Icons.route_outlined,
              color: _isOptimized ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () {
              final credits = creditsAsync.value ?? [];
              _optimizeRoute(credits);
            },
            tooltip: _isOptimized
                ? 'Desactivar ruta optimizada'
                : 'Optimizar ruta (más cerca al más lejos)',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: AppStrings.searchByNameOrId,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
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
          // Credits List
          Expanded(
            child: creditsAsync.when(
              data: (credits) {
                if (credits.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay créditos disponibles',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                // Precargar datos si aún no se han precargado (asíncrono, no bloquea)
                if (_preloadedData == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _preloadData(credits);
                  });
                }

                // Usar créditos ordenados si la optimización está activada, sino usar los originales
                final creditsToShow = _isOptimized && _sortedCredits.isNotEmpty
                    ? _sortedCredits
                    : credits;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: creditsToShow.length,
                  cacheExtent: 1000, // Aumentar cache para mejor rendimiento
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  physics: const BouncingScrollPhysics(), // Scroll más fluido
                  itemBuilder: (context, index) {
                    final credit = creditsToShow[index];
                    return _buildCreditCardOptimized(credit);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error: ${error.toString()}',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
    );
  }

  // Calcular cuotas atrasadas basándose en fechas
  int _calculateOverdueInstallments(
      CreditEntity credit, List<CollectionEntity> collections) {
    // Si no tiene saldo restante, no hay cuotas atrasadas
    if (credit.totalBalance <= 0) {
      return 0;
    }

    final now = DateTime.now();
    final startDate = credit.createdAt;
    final endDate = startDate.add(Duration(days: credit.totalInstallments));

    // Si la fecha actual es después de la fecha final, no hay más cuotas pendientes
    if (now.isAfter(endDate)) {
      // Si aún tiene saldo pendiente después de la fecha final, todas las cuotas restantes están atrasadas
      final expectedPaidInstallments = credit.totalInstallments;
      final actualPaidInstallments = credit.paidInstallments;
      return expectedPaidInstallments - actualPaidInstallments;
    }

    // Si no tiene abonos, calcular desde la primera cuota que debería haberse pagado
    if (collections.isEmpty) {
      // La primera cuota debería pagarse al día siguiente de la fecha de inicio
      final firstDueDate = startDate.add(const Duration(days: 1));

      // Si ya pasó la fecha de la primera cuota, calcular cuántas cuotas están atrasadas
      if (now.isAfter(firstDueDate)) {
        final daysOverdue = now.difference(firstDueDate).inDays;
        // Cada día es una cuota, así que los días de atraso son las cuotas atrasadas
        // Pero no puede exceder el total de cuotas
        return daysOverdue > credit.totalInstallments
            ? credit.totalInstallments
            : daysOverdue;
      }
      return 0;
    }

    // Si tiene abonos, calcular basándose en el último abono
    // Ordenar abonos por fecha (más reciente primero)
    final sortedCollections = List<CollectionEntity>.from(collections)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final lastPaymentDate = sortedCollections.first.paymentDate;

    // Calcular cuántos días han pasado desde el último abono
    final daysSinceLastPayment = now.difference(lastPaymentDate).inDays;

    // Si han pasado más de 1 día desde el último abono, hay cuotas atrasadas
    // Cada día después del último abono es una cuota atrasada
    if (daysSinceLastPayment > 1) {
      // No puede exceder las cuotas restantes
      final remainingInstallments =
          credit.totalInstallments - credit.paidInstallments;
      final overdue = daysSinceLastPayment - 1;
      return overdue > remainingInstallments ? remainingInstallments : overdue;
    }

    // Si el último abono fue hoy o ayer, no hay cuotas atrasadas
    return 0;
  }

  // Versión optimizada que usa datos precargados
  Widget _buildCreditCardOptimized(credit) {
    final cacheKey = '${credit.id}_${credit.clientId}';
    final cachedData = _preloadedData?[cacheKey] ?? _dataCache[cacheKey];

    // Si no hay datos precargados, usar la versión con FutureBuilder
    if (cachedData == null) {
      return _buildCreditCard(credit);
    }

    final client = cachedData['client'] as ClientEntity?;
    final collections = cachedData['collections'] as List<CollectionEntity>;
    final summary = cachedData['summary'] as CreditSummaryEntity?;

    return _buildCreditCardContent(credit, client, collections, summary);
  }

  Widget _buildCreditCard(credit) {
    // Verificar si los datos están en cache
    final cacheKey = '${credit.id}_${credit.clientId}';
    final cachedData = _dataCache[cacheKey];

    final businessId = ref.read(currentUserProvider)?.businessId;
    final creditRepository = ref.read(creditRepositoryProvider);
    return FutureBuilder<List<dynamic>>(
      future: cachedData != null
          ? Future.value([
              cachedData['client'],
              cachedData['collections'],
              cachedData['summary'],
            ])
          : Future.wait<dynamic>([
              ref.read(clientRepositoryProvider).getClientById(credit.clientId),
              ref.read(collectionRepositoryProvider).getCollectionsByCreditId(
                    credit.id,
                    businessId: businessId,
                  ),
              creditRepository.getCreditSummaryById(credit.id),
            ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Mostrar un placeholder mientras carga con altura fija para evitar saltos
          return Container(
            height: 400, // Altura fija para evitar distorsión
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final results = snapshot.data!;
        final client = results[0] as ClientEntity?;
        final collections = results[1] as List<CollectionEntity>;
        final summary = results.length > 2
            ? results[2] as CreditSummaryEntity?
            : null;

        // Guardar en cache si no estaba
        if (cachedData == null && snapshot.hasData) {
          _dataCache[cacheKey] = {
            'client': client,
            'collections': collections,
            'summary': summary,
          };
        }

        return _buildCreditCardContent(credit, client, collections, summary);
      },
    );
  }

  Widget _buildCreditCardContent(
    CreditEntity credit,
    ClientEntity? client,
    List<CollectionEntity> collections, [
    CreditSummaryEntity? summary,
  ]) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    // Saldo restante desde API summary (como en la web), no del listado de créditos
    final effectiveBalance = summary?.totalBalance ?? credit.totalBalance;

    final clientName = client?.name ?? 'Cliente';
    final clientPhone = client?.phone ?? '';

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final matchesName = clientName.toLowerCase().contains(_searchQuery);
      final matchesPhone = clientPhone.contains(_searchQuery);
      final matchesId =
          (client?.documentId ?? '').toLowerCase().contains(_searchQuery);

      if (!matchesName && !matchesPhone && !matchesId) {
        return const SizedBox.shrink();
      }
    }

    // Calcular fechas del préstamo
    final startDate = credit.createdAt;
    final endDate = startDate.add(Duration(days: credit.totalInstallments));

    // Calcular cuotas atrasadas (usar saldo efectivo para considerar crédito pagado)
    final calculatedOverdueInstallments = effectiveBalance <= 0
        ? 0
        : _calculateOverdueInstallments(credit, collections);

    // Ordenar por fecha de pago (más reciente primero) para mostrar siempre el último abono real
    final sortedByDate = List<CollectionEntity>.from(collections)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    final lastCollections = sortedByDate.take(3).toList();
    final lastPayment = sortedByDate.isNotEmpty ? sortedByDate.first : null;

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          if (client != null) {
            context.push('/client-visit/${client.id}');
          }
        },
        child: Container(
          key: ValueKey('credit_${credit.id}'), // Key única para cada tarjeta
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textSecondary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and phone
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (clientPhone.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.phone,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      onPressed: () async {
                        // Limpiar el número de teléfono (eliminar espacios, guiones, etc.)
                        final cleanPhone = clientPhone
                            .replaceAll(' ', '')
                            .replaceAll('-', '')
                            .replaceAll('(', '')
                            .replaceAll(')', '')
                            .replaceAll('+', '');

                        final uri = Uri.parse('tel:$cleanPhone');

                        try {
                          // Intentar abrir el dialer con el número
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.platformDefault,
                            );
                          } else {
                            // Si no puede lanzar, intentar sin verificación
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error al abrir el dialer: ${e.toString()}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
              if (clientPhone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  clientPhone,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ],
              if (_isOptimized && _distances.containsKey(credit.id)) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_car,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'A ${_distances[credit.id]!.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Divider
              Container(
                height: 1,
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
              const SizedBox(height: 20),
              // Fechas del préstamo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.startDate,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatter.format(startDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          AppStrings.endDate,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatter.format(endDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Divider
              Container(
                height: 1,
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
              const SizedBox(height: 20),
              // Saldo Total del Préstamo y Saldo Restante
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.totalLoanAmount,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(credit.totalToPay),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          AppStrings.remainingBalance,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(effectiveBalance),
                          style: TextStyle(
                            color: effectiveBalance > 0
                                ? AppColors.error
                                : AppColors.success,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Últimos Abonos
              if (lastCollections.isNotEmpty) ...[
                const Text(
                  AppStrings.lastPayments,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...lastCollections.map((collection) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormatter.format(collection.paymentDate),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            formatter.format(collection.amount),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 16),
              // Credit details in 3 columns
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(
                    AppStrings.installmentValueLabel,
                    formatter.format(credit.installmentAmount),
                  ),
                  _buildInfoColumn(
                    AppStrings.overdueInstallmentsLabel,
                    calculatedOverdueInstallments.toString(),
                    valueColor: calculatedOverdueInstallments > 0
                        ? AppColors.error
                        : AppColors.success,
                  ),
                  _buildInfoColumn(
                    AppStrings.lastPaymentLabel,
                    lastPayment != null
                        ? dateFormatter.format(lastPayment.paymentDate)
                        : 'N/A',
                    valueColor: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
