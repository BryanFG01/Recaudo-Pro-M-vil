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
import '../../../domain/entities/payment_attempt_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/payment_attempt_provider.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class MyWalletScreen extends ConsumerStatefulWidget {
  const MyWalletScreen({super.key});

  @override
  ConsumerState<MyWalletScreen> createState() => _MyWalletScreenState();
}

/// Filtro de estado de recaudo en Mi cartera.
/// Pagaron = realizaron abono o pago de cuota completa (tienen al menos una colección hoy).
/// No pagaron = registramos "No pago" (tienen intento NOT_PAID hoy).
enum WalletFilter {
  todos('Todos'),
  pagaron('Pagaron (abono o cuota completa)'),
  noPagaron('No pagaron'),
  pendiente('Pendiente');

  const WalletFilter(this.label);
  final String label;
}

class _MyWalletScreenState extends ConsumerState<MyWalletScreen> {
  final _searchController = TextEditingController();
  bool _isPreloading = false;
  String _searchQuery = '';
  bool _isOptimized = false;
  Position? _currentPosition;
  List<dynamic> _sortedCredits = [];
  final Map<String, double> _distances = {};
  // Cache para evitar reconstrucciones innecesarias
  final Map<String, Map<String, dynamic>> _dataCache = {};
  // Datos precargados para mejor rendimiento
  Map<String, Map<String, dynamic>>? _preloadedData;

  /// Al ingresar a Mi cartera no se selecciona ningún filtro; la lista se muestra al elegir uno.
  WalletFilter? _walletFilter = null;

  /// Para limpiar creditsWithActionTodayProvider cuando cambia el día (la card vuelve a aparecer al otro día).
  DateTime? _lastActionDay;

  // Precargar todos los datos de una vez para mejor rendimiento
  Future<void> _preloadData(List<CreditEntity> credits) async {
    if (_preloadedData != null || _isPreloading) return;

    setState(() => _isPreloading = true);

    final businessId = ref.read(currentUserProvider)?.businessId;
    if (businessId == null) {
      setState(() => _isPreloading = false);
      return;
    }

    final preloaded = <String, Map<String, dynamic>>{};

    final creditRepository = ref.read(creditRepositoryProvider);
    final paymentAttemptRepo = ref.read(paymentAttemptRepositoryProvider);

    // Fetch essential data for ALL credits in parallel where possible
    try {
      final futures = credits.map((credit) async {
        final cacheKey = '${credit.id}_${credit.clientId}';
        try {
          final results = await Future.wait<dynamic>([
            ref.read(clientRepositoryProvider).getClientById(credit.clientId),
            ref.read(collectionRepositoryProvider).getCollectionsByCreditId(
                  credit.id,
                  businessId: businessId,
                ),
            creditRepository.getCreditSummaryById(credit.id),
            paymentAttemptRepo.getPaymentAttemptsByCreditId(credit.id),
          ]);
          final attempts = results[3] as List<PaymentAttemptEntity>;
          final collections = results[1] as List<CollectionEntity>;
          preloaded[cacheKey] = {
            'client': results[0],
            'collections': collections,
            'summary': results[2],
            'noPaymentDays': _daysFromPaymentAttempts(attempts),
            'hasPaymentToday': _hasPaymentToday(collections),
            'hasNoPagoToday': _hasNoPagoToday(attempts),
          };
        } catch (e) {
          debugPrint('Error preloading card $cacheKey: $e');
        }
      });

      await Future.wait(futures);
    } finally {
      if (mounted) {
        setState(() {
          _preloadedData = preloaded;
          _dataCache.addAll(preloaded);
          _isPreloading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dataCache.clear();
    _preloadedData = null;
    super.dispose();
  }

  /// Días acumulados sin pago desde GET /api/payment-attempts/credit/{creditId}.
  /// El backend puede devolver accumulated_no_payment_days como null, así que
  /// contamos directamente la cantidad de intentos NOT_PAID como fallback.
  static int _daysFromPaymentAttempts(List<PaymentAttemptEntity> attempts) {
    if (attempts.isEmpty) return 0;
    final notPaidAttempts =
        attempts.where((a) => a.status == 'NOT_PAID').toList();
    if (notPaidAttempts.isEmpty) return 0;
    // Intentar usar accumulated_no_payment_days del más reciente
    final sorted = List<PaymentAttemptEntity>.from(notPaidAttempts)
      ..sort((a, b) {
        final ad = a.attemptDate ?? DateTime(0);
        final bd = b.attemptDate ?? DateTime(0);
        return bd.compareTo(ad);
      });
    final fromApi = sorted.first.accumulatedNoPaymentDays;
    // Si el backend devuelve null/0, contar la cantidad de NOT_PAID
    return fromApi > 0 ? fromApi : notPaidAttempts.length;
  }

  /// Misma fecha (año/mes/día) en zona horaria local. Evita que UTC invierta el día.
  static bool _isToday(DateTime d) {
    final local = d.isUtc ? d.toLocal() : d;
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  /// True si hoy hubo al menos un abono o pago de cuota completa (colección).
  static bool _hasPaymentToday(List<CollectionEntity> collections) {
    return collections.any((c) => _isToday(c.paymentDate));
  }

  /// True si hoy se registró "No pago" (intento NOT_PAID).
  static bool _hasNoPagoToday(List<PaymentAttemptEntity> attempts) {
    return attempts.any((a) =>
        a.status == 'NOT_PAID' &&
        a.attemptDate != null &&
        _isToday(a.attemptDate!));
  }

  /// Categoría única por crédito: un crédito es solo una de estas tres.
  static WalletFilter _category(bool hasPaymentToday, bool hasNoPagoToday) {
    if (hasPaymentToday) return WalletFilter.pagaron;
    if (hasNoPagoToday) return WalletFilter.noPagaron;
    return WalletFilter.pendiente;
  }

  /// Incluir crédito en la lista según filtro actual. Una sola validación precisa.
  static bool _shouldShowCredit(
    WalletFilter filter,
    WalletFilter category,
    bool hadActionToday,
  ) {
    // Con acción hoy: no mostrar en Todos ni Pendiente (la card se esconde)
    if (hadActionToday &&
        (filter == WalletFilter.todos || filter == WalletFilter.pendiente)) {
      return false;
    }
    switch (filter) {
      case WalletFilter.todos:
        return true;
      case WalletFilter.pagaron:
        return category == WalletFilter.pagaron;
      case WalletFilter.noPagaron:
        return category == WalletFilter.noPagaron;
      case WalletFilter.pendiente:
        return category == WalletFilter.pendiente;
    }
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          backgroundColor: AppColors.background(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)),
            onPressed: () => context.pop(),
          ),
          title: Text(
            AppStrings.myWallet,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary(context),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Recaudo'),
              Tab(text: 'Ventas'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.sync, color: AppColors.textPrimary(context)),
              tooltip: 'Actualizar datos',
              onPressed: () {
                ref.invalidate(creditsProvider);
                setState(() {
                  _preloadedData = null;
                  _dataCache.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Actualizando datos...'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                _isOptimized ? Icons.route : Icons.route_outlined,
                color: _isOptimized
                    ? AppColors.primary
                    : AppColors.textSecondary(context),
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
        body: TabBarView(
          children: [
            _buildRecaudoTab(context, creditsAsync),
            _buildVentasTab(context),
          ],
        ),
        bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildRecaudoTab(
      BuildContext context, AsyncValue<List<CreditEntity>> creditsAsync) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: AppStrings.searchByNameOrId,
              hintStyle: TextStyle(color: AppColors.textSecondary(context)),
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textSecondary(context)),
              filled: true,
              fillColor: AppColors.surface(context),
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
        // Filtro desplegable: vacío al ingresar; al seleccionar se muestra la lista
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<WalletFilter?>(
            value: _walletFilter,
            hint: Text(
              'Seleccione un filtro',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            decoration: InputDecoration(
              labelText: 'Estado de recaudo',
              labelStyle: TextStyle(color: AppColors.textSecondary(context)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface(context),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: AppColors.surface(context),
            style: TextStyle(color: AppColors.textPrimary(context)),
            items: WalletFilter.values
                .map((f) => DropdownMenuItem<WalletFilter?>(
                      value: f,
                      child: Text(f.label),
                    ))
                .toList(),
            onChanged: (WalletFilter? value) {
              setState(() => _walletFilter = value);
            },
          ),
        ),
        // Credits List (filtrada por estado; datos del GET pintan al instante vía provider)
        Expanded(
          child: creditsAsync.when(
            data: (credits) {
              if (credits.isEmpty) {
                return Center(
                  child: Text(
                    'No hay créditos disponibles',
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                );
              }

              // Precargar datos si aún no se han precargado
              if (_preloadedData == null && !_isPreloading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _preloadData(credits);
                });
              }

              if (_preloadedData == null || _isPreloading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Actualizando cartera...',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Usar créditos ordenados si la optimización está activada
              final creditsToShow = _isOptimized && _sortedCredits.isNotEmpty
                  ? _sortedCredits
                  : credits;

              return Consumer(
                builder: (context, ref, _) {
                  // Sin filtro seleccionado: mostrar solo los que no han tenido ninguna acción (pendientes)
                  final filter = _walletFilter ?? WalletFilter.pendiente;

                  // Limpiar créditos con acción cuando cambia el día para que la card pueda aparecer de nuevo en Pendiente
                  final today = DateTime(DateTime.now().year,
                      DateTime.now().month, DateTime.now().day);
                  if (_lastActionDay != null &&
                      _lastActionDay!.isBefore(today)) {
                    ref.read(creditsWithActionTodayProvider.notifier).state =
                        <String>{};
                    if (mounted) setState(() => _lastActionDay = today);
                  } else if (_lastActionDay == null) {
                    _lastActionDay = today;
                  }

                  final creditsWithActionToday =
                      ref.watch(creditsWithActionTodayProvider);

                  // Una sola pasada: por cada crédito obtenemos datos, categoría y decidimos si mostrar
                  // No enlistar en recaudo los créditos creados hoy; solo se ven en Ventas hasta el día siguiente
                  final seenIds = <String>{};
                  final filteredCredits = <CreditEntity>[];
                  for (final credit in creditsToShow) {
                    if (seenIds.contains(credit.id)) continue;
                    seenIds.add(credit.id);

                    final createdLocal = credit.createdAt.toLocal();
                    final createdDay = DateTime(createdLocal.year,
                        createdLocal.month, createdLocal.day);

                    // Si es de hoy, no se cobra hoy.
                    // Se enlista en Ventas y pasa a Recaudo mañana.
                    if (createdDay == today) continue;

                    final cacheKey = '${credit.id}_${credit.clientId}';
                    final cache =
                        _preloadedData?[cacheKey] ?? _dataCache[cacheKey];

                    // Validar si ya está pagado (saldo <= 0)
                    double currentBalance = credit.totalBalance;
                    if (cache != null && cache['summary'] != null) {
                      final summary = cache['summary'] as CreditSummaryEntity;
                      currentBalance = summary.totalBalance;
                    }

                    if (currentBalance <= 0) continue;

                    final hasPaymentToday = cache != null
                        ? (cache['hasPaymentToday'] as bool? ?? false)
                        : false;
                    final attempts = ref
                        .watch(paymentAttemptsByCreditIdProvider(credit.id))
                        .valueOrNull;
                    final hasNoPagoToday = _hasNoPagoToday(attempts ?? []);

                    final category = _category(hasPaymentToday, hasNoPagoToday);
                    final hadActionToday =
                        creditsWithActionToday.contains(credit.id);

                    if (_shouldShowCredit(filter, category, hadActionToday)) {
                      filteredCredits.add(credit);
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCredits.length,
                    cacheExtent: 1000,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final credit = filteredCredits[index];
                      return _buildCreditCardWithProvider(credit);
                    },
                  );
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
    );
  }

  /// Pestaña Ventas: clientes nuevos creados hoy (no se pierden en la lista de recaudo).
  Widget _buildVentasTab(BuildContext context) {
    final clientsAsync = ref.watch(clientsCreatedTodayProvider);
    return clientsAsync.when(
      data: (clients) {
        if (clients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay clientes nuevos creados hoy',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Consumer(
          builder: (context, ref, _) {
            final creditsAsync = ref.watch(creditsProvider);
            final credits = creditsAsync.valueOrNull ?? [];
            final creditByClientId = {for (var c in credits) c.clientId: c};
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                final credit = creditByClientId[client.id];
                return _buildVentaCard(context, client, credit);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Error al cargar ventas',
          style: TextStyle(color: AppColors.error, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildVentaCard(
      BuildContext context, ClientEntity client, CreditEntity? credit) {
    return InkWell(
      onTap: () => context.push('/client-visit/${client.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (client.phone.isNotEmpty)
                    Text(
                      client.phone,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),
                  Text(
                    'Creado ${DateFormat('dd/MM/yyyy HH:mm').format(client.createdAt.toLocal())}',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (credit != null)
              Text(
                NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                    .format(credit.totalAmount),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  /// Tarjeta que usa provider para los días (pinta al instante al invalidar).
  Widget _buildCreditCardWithProvider(credit) {
    final cacheKey = '${credit.id}_${credit.clientId}';
    final cachedData = _preloadedData?[cacheKey] ?? _dataCache[cacheKey];

    if (cachedData == null) {
      return _buildCreditCard(credit);
    }

    final client = cachedData['client'] as ClientEntity?;
    final collections = cachedData['collections'] as List<CollectionEntity>;
    final summary = cachedData['summary'] as CreditSummaryEntity?;

    return Consumer(
      builder: (context, ref, _) {
        final attemptsAsync =
            ref.watch(paymentAttemptsByCreditIdProvider(credit.id));
        final noPaymentDays = attemptsAsync.valueOrNull != null
            ? _daysFromPaymentAttempts(attemptsAsync.value!)
            : (cachedData['noPaymentDays'] as int?) ?? 0;
        return _buildCreditCardContent(
          credit,
          client,
          collections,
          summary,
          noPaymentDays,
          () => _navigateToClientVisit(client),
        );
      },
    );
  }

  void _navigateToClientVisit(ClientEntity? client) {
    if (client == null) return;
    context.push('/client-visit/${client.id}').then((_) {
      if (mounted) {
        ref.invalidate(creditsProvider);
        ref.invalidate(paymentAttemptsByCreditIdProvider);
        setState(() {
          _dataCache.clear();
          _preloadedData = null;
        });
      }
    });
  }

  Widget _buildCreditCard(credit) {
    // Verificar si los datos están en cache
    final cacheKey = '${credit.id}_${credit.clientId}';
    final cachedData = _dataCache[cacheKey];

    final businessId = ref.read(currentUserProvider)?.businessId;
    final creditRepository = ref.read(creditRepositoryProvider);
    final paymentAttemptRepo = ref.read(paymentAttemptRepositoryProvider);
    return FutureBuilder<List<dynamic>>(
      future: cachedData != null
          ? Future.value([
              cachedData['client'],
              cachedData['collections'],
              cachedData['summary'],
              cachedData['noPaymentDays'] ?? 0,
            ])
          : Future.wait<dynamic>([
              ref.read(clientRepositoryProvider).getClientById(credit.clientId),
              ref.read(collectionRepositoryProvider).getCollectionsByCreditId(
                    credit.id,
                    businessId: businessId,
                  ),
              creditRepository.getCreditSummaryById(credit.id),
              paymentAttemptRepo.getPaymentAttemptsByCreditId(credit.id),
            ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Mostrar un placeholder mientras carga con altura fija para evitar saltos
          return Container(
            height: 400, // Altura fija para evitar distorsión
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary(context).withOpacity(0.1),
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
        final summary =
            results.length > 2 ? results[2] as CreditSummaryEntity? : null;
        int noPaymentDays = 0;
        if (results.length > 3) {
          if (results[3] is int) {
            noPaymentDays = results[3] as int;
          } else if (results[3] is List<PaymentAttemptEntity>) {
            noPaymentDays = _daysFromPaymentAttempts(
                results[3] as List<PaymentAttemptEntity>);
          }
        }

        // Guardar en cache si no estaba
        if (cachedData == null && snapshot.hasData) {
          final attemptsForCache =
              results.length > 3 && results[3] is List<PaymentAttemptEntity>
                  ? results[3] as List<PaymentAttemptEntity>
                  : <PaymentAttemptEntity>[];
          _dataCache[cacheKey] = {
            'client': client,
            'collections': collections,
            'summary': summary,
            'noPaymentDays': noPaymentDays,
            'hasPaymentToday': _hasPaymentToday(collections),
            'hasNoPagoToday': _hasNoPagoToday(attemptsForCache),
          };
        }

        return _buildCreditCardContent(
            credit, client, collections, summary, noPaymentDays);
      },
    );
  }

  Widget _buildCreditCardContent(
    CreditEntity credit,
    ClientEntity? client,
    List<CollectionEntity> collections, [
    CreditSummaryEntity? summary,
    int noPaymentDays = 0,
    void Function()? onVisitTap,
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

    // Cuotas atrasadas: usar el mayor entre el valor del API (overdueInstallments)
    // y los días acumulados sin pago (noPaymentDays de payment-attempts).
    final displayDays = noPaymentDays > 0
        ? noPaymentDays
        : credit.overdueInstallments;

    // Ordenar por fecha de pago (más reciente primero) para mostrar siempre el último abono real
    final sortedByDate = List<CollectionEntity>.from(collections)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    final lastCollections = sortedByDate.take(3).toList();
    final lastPayment = sortedByDate.isNotEmpty ? sortedByDate.first : null;

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          if (onVisitTap != null) {
            onVisitTap();
          } else if (client != null) {
            context.push('/client-visit/${client.id}');
          }
        },
        child: Container(
          key: ValueKey('credit_${credit.id}'), // Key única para cada tarjeta
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textSecondary(context).withOpacity(0.1),
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
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
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
                color: AppColors.textSecondary(context).withOpacity(0.2),
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
                        Text(
                          AppStrings.startDate,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatter.format(startDate),
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
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
                        Text(
                          AppStrings.endDate,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatter.format(endDate),
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
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
                color: AppColors.textSecondary(context).withOpacity(0.2),
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
                        Text(
                          AppStrings.totalLoanAmount,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(credit.totalToPay),
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
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
                        Text(
                          AppStrings.remainingBalance,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
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
                Text(
                  AppStrings.lastPayments,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
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
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
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
                    displayDays.toString(),
                    valueColor:
                        displayDays > 0 ? AppColors.error : AppColors.success,
                  ),
                  _buildInfoColumn(
                    AppStrings.lastPaymentLabel,
                    lastPayment != null
                        ? dateFormatter.format(lastPayment.paymentDate)
                        : 'N/A',
                    valueColor: AppColors.textSecondary(context),
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
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
