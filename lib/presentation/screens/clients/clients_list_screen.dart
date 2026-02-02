import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/client_entity.dart';
import '../../../domain/entities/credit_entity.dart';
import '../../providers/client_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class ClientsListScreen extends ConsumerStatefulWidget {
  const ClientsListScreen({super.key});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<CreditEntity?> _getClientCredit(String clientId) async {
    try {
      final credits = await ref.read(creditsProvider.future);
      return credits.firstWhere(
        (credit) => credit.clientId == clientId && credit.totalBalance > 0,
        orElse: () => throw Exception('No credit'),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo realizar la llamada'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _locateClient(ClientEntity client) async {
    if (client.latitude != null && client.longitude != null) {
      await _openNavigationApp(client.latitude!, client.longitude!);
    } else if (client.address != null && client.address!.isNotEmpty) {
      // Si no hay coordenadas pero hay dirección, abrir con la dirección
      await _openNavigationWithAddress(client.address!);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente no tiene ubicación registrada'),
          backgroundColor: AppColors.warning,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom:
                      BorderSide(color: AppColors.textSecondary, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Clientes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon:
                        const Icon(Icons.search, color: AppColors.textPrimary),
                    onPressed: () {
                      // Búsqueda ya está disponible en el campo de texto
                    },
                  ),
                ],
              ),
            ),
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o cédula...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
            // Clients List
            Expanded(
              child: clientsAsync.when(
                data: (clients) {
                  // Filtrar clientes por búsqueda
                  final filteredClients = _searchQuery.isEmpty
                      ? clients
                      : clients.where((client) {
                          return client.name
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              (client.documentId
                                      ?.toLowerCase()
                                      .contains(_searchQuery) ??
                                  false);
                        }).toList();

                  if (filteredClients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No hay clientes registrados'
                                : 'No se encontraron clientes',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(clientsProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        return _buildClientCard(client);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar clientes',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(clientsProvider);
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildClientCard(ClientEntity client) {
    return FutureBuilder<CreditEntity?>(
      future: _getClientCredit(client.id),
      builder: (context, snapshot) {
        final hasDebt = snapshot.data != null;
        final credit = snapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasDebt
                                ? AppColors.error.withOpacity(0.2)
                                : AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasDebt ? 'Debe' : 'No Debe',
                            style: TextStyle(
                              color:
                                  hasDebt ? AppColors.error : AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (credit != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '\$${credit.totalBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Locate Button
                  IconButton(
                    icon: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    onPressed: () => _locateClient(client),
                    tooltip: 'Ubicar',
                  ),
                  // Call Button
                  if (client.phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      onPressed: () => _callClient(client.phone),
                      tooltip: 'Llamar',
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
