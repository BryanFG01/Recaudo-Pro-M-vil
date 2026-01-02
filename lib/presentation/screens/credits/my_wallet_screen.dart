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
import '../../providers/client_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/credit_provider.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
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

                // Usar créditos ordenados si la optimización está activada, sino usar los originales
                final creditsToShow = _isOptimized && _sortedCredits.isNotEmpty
                    ? _sortedCredits
                    : credits;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: creditsToShow.length,
                  itemBuilder: (context, index) {
                    final credit = creditsToShow[index];
                    return _buildCreditCard(credit);
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
    );
  }

  Widget _buildCreditCard(credit) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        ref.read(clientRepositoryProvider).getClientById(credit.clientId),
        ref
            .read(collectionRepositoryProvider)
            .getCollectionsByCreditId(credit.id),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final results = snapshot.data!;
        final client = results[0] as ClientEntity?;
        final collections = results[1] as List<CollectionEntity>;

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

        // Obtener los últimos 3 abonos
        final lastCollections = collections.take(3).toList();

        return InkWell(
          onTap: () {
            if (client != null) {
              context.push('/client-visit/${client.id}');
            }
          },
          child: Container(
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
                            formatter.format(credit.totalAmount),
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
                            formatter.format(credit.totalBalance),
                            style: TextStyle(
                              color: credit.totalBalance > 0
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
                      credit.overdueInstallments.toString(),
                      valueColor: credit.overdueInstallments > 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    _buildInfoColumn(
                      AppStrings.lastPaymentLabel,
                      credit.lastPaymentDate != null
                          ? dateFormatter.format(credit.lastPaymentDate!)
                          : 'N/A',
                      valueColor: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
