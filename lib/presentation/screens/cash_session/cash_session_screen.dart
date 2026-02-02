import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/thousands_separator_input_formatter.dart';
import '../../../domain/entities/cash_session_entity.dart';
import '../../../domain/entities/cash_session_flow_entity.dart';
import '../../../domain/entities/dashboard_stats_entity.dart';
import '../../../domain/entities/withdrawal_entity.dart';
import '../../../domain/entities/withdrawals_data_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cash_session_provider.dart';
import '../../providers/collection_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/stat_card.dart';

class CashSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const CashSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<CashSessionScreen> createState() => _CashSessionScreenState();
}

class _CashSessionScreenState extends ConsumerState<CashSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasScrolledToTop = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal([String? sessionIdForRequest]) async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final sid = sessionIdForRequest ?? widget.sessionId;
    if (sid.isEmpty || sid == 'active') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.noActiveCashSession),
            backgroundColor: AppColors.warning,
          ),
        );
      }
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
      final useCase = ref.read(createWithdrawalUseCaseProvider);
      await useCase(
        cashSessionId: sid,
        userId: user.id,
        amount: amount,
        reason: _reasonController.text.trim().isEmpty
            ? 'Sin motivo'
            : _reasonController.text.trim(),
        isApproved: false,
      );
      _amountController.clear();
      _reasonController.clear();
      ref.invalidate(withdrawalsByUserProvider(user.id));
      ref.invalidate(cashSessionFlowProvider(sid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.withdrawalRequested),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : e}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isActiveRoute = widget.sessionId == 'active';
    // Ruta "active": GET /api/cash-sessions/user/{userId} para saldo inicial; recaudo del día para card Retiro; GET /api/withdrawals/user/{userId} para listado y form.
    final cashSessionByUserAsync = user != null && isActiveRoute
        ? ref.watch(cashSessionByUserProvider(user.id))
        : const AsyncValue<CashSessionEntity?>.data(null);
    final dashboardStatsAsync = user != null && isActiveRoute
        ? ref.watch(dashboardStatsProvider(0))
        : const AsyncValue<DashboardStatsEntity>.loading();
    final withdrawalsAsync = user != null
        ? ref.watch(withdrawalsByUserProvider(user.id))
        : const AsyncValue<WithdrawalsDataEntity>.data(
            WithdrawalsDataEntity(withdrawals: []));
    // effectiveSessionId para flow: GET /api/cash-sessions/flow/:id (ruta active).
    final sessionForFlow = cashSessionByUserAsync.valueOrNull;
    final dataForFlow = withdrawalsAsync.valueOrNull;
    final effectiveSessionId =
        isActiveRoute && (sessionForFlow != null || dataForFlow != null)
            ? (sessionForFlow?.id ??
                (dataForFlow?.cashSessionId?.isNotEmpty == true
                    ? dataForFlow!.cashSessionId
                    : (dataForFlow?.withdrawals.isNotEmpty == true
                        ? dataForFlow!.withdrawals.first.cashSessionId
                        : null)))
            : null;
    final flowAsync = isActiveRoute && (effectiveSessionId?.isNotEmpty == true)
        ? ref.watch(cashSessionFlowProvider(effectiveSessionId!))
        : const AsyncValue<CashSessionFlowEntity?>.data(null);
    final sessionAsync =
        isActiveRoute ? null : ref.watch(cashSessionProvider(widget.sessionId));

    if (isActiveRoute && user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            AppStrings.cashSession,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Inicia sesión para ver la sesión de caja',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          AppStrings.cashSession,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!isActiveRoute)
            ref.invalidate(cashSessionProvider(widget.sessionId));
          if (user != null) {
            if (isActiveRoute) {
              ref.invalidate(cashSessionByUserProvider(user.id));
              ref.invalidate(dashboardStatsProvider(0));
              if (effectiveSessionId != null && effectiveSessionId.isNotEmpty) {
                ref.invalidate(cashSessionFlowProvider(effectiveSessionId));
              }
            }
            ref.invalidate(withdrawalsByUserProvider(user.id));
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isActiveRoute)
                withdrawalsAsync.when(
                  data: (data) {
                    // Saldo inicial/actual desde GET /api/cash-sessions/user/{userId} si existe
                    final session = cashSessionByUserAsync.valueOrNull;
                    if (!_hasScrolledToTop) {
                      _hasScrolledToTop = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                      });
                    }
                    final recaudoTotal =
                        dashboardStatsAsync.valueOrNull?.totalCollected ?? 0.0;
                    return _buildContentFromWithdrawalsData(
                      data,
                      cashSession: session,
                      flowAsync: flowAsync,
                      recaudoTotal: recaudoTotal,
                      hasSessionId: effectiveSessionId != null &&
                          effectiveSessionId.isNotEmpty,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al cargar datos: ${e.toString()}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                )
              else
                sessionAsync!.when(
                  data: (session) {
                    if (session == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildNoActiveSession(),
                          const SizedBox(height: 28),
                          _buildMyWithdrawalsSection(withdrawalsAsync),
                        ],
                      );
                    }
                    return _buildSessionContent(
                      session,
                      widget.sessionId,
                      withdrawalsAsync,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al cargar sesión: ${e.toString()}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Contenido: card saldo inicial y total recaudo desde flow (GET /api/cash-sessions/flow/:id); form retiro; historial mis retiros.
  Widget _buildContentFromWithdrawalsData(
    WithdrawalsDataEntity data, {
    CashSessionEntity? cashSession,
    required AsyncValue<CashSessionFlowEntity?> flowAsync,
    double recaudoTotal = 0.0,
    bool hasSessionId = false,
  }) {
    final flow = flowAsync.valueOrNull;
    // Caja inicial: flow.initial_balance o fallback a sesión/withdrawals.
    final initialBalance = flow?.initialBalance ??
        cashSession?.initialBalance ??
        data.initialBalance ??
        0.0;
    // Para enviar retiro: sesión de caja (id) o cash_session_id de respuesta o del primer retiro.
    final effectiveSessionId = cashSession?.id ??
        (data.cashSessionId?.isNotEmpty == true
            ? data.cashSessionId
            : (data.withdrawals.isNotEmpty
                ? data.withdrawals.first.cashSessionId
                : null));
    // Total recaudo mostrado = total_collected − total_withdrawals_approved. Lo calculamos en frontend
    // para que el descuento coincida siempre con la suma de retiros aprobados (evita errores del backend).
    final double totalRecaudoMostrado;
    final bool totalRecaudoLoading;
    if (hasSessionId) {
      totalRecaudoLoading = flowAsync.isLoading;
      if (flow != null) {
        totalRecaudoMostrado =
            flow.totalCollected - flow.totalWithdrawalsApproved;
      } else {
        totalRecaudoMostrado = 0.0;
      }
    } else {
      totalRecaudoLoading = false;
      totalRecaudoMostrado = recaudoTotal;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card Caja inicial (desde flow o sesión)
        StatCard(
          title: AppStrings.initialBalance,
          amount: initialBalance,
          subtitle: 'Sesión de caja',
        ),
        const SizedBox(height: 16),
        // Card Total recaudo (flow: total_collected − total_withdrawals_approved)
        totalRecaudoLoading
            ? _buildTotalRecaudoLoadingCard()
            : StatCard(
                title: AppStrings.totalCollected,
                amount: totalRecaudoMostrado,
                subtitle: 'Dentro de sesión de caja',
              ),
        if (flow != null) ...[
          const SizedBox(height: 16),
          StatCard(
            title: AppStrings.cajaInicialRestante,
            amount: flow.cajaInicialRestante,
            subtitle: 'Vista de saldo inicial restante',
          ),
          const SizedBox(height: 16),
          StatCard(
            title: AppStrings.saldoDisponible,
            amount: flow.saldoDisponibleCalculado,
            subtitle:
                'Saldo inicial + recaudo (balance inicial + recaudo − retiros aprobados)', // TODO: traducir
          ),
        ],
        const SizedBox(height: 24),
        // Formulario Nuevo Retiro
        Text(
          AppStrings.newWithdrawal,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: AppStrings.amount,
                hint: 'Ej: 20.000',
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
              const SizedBox(height: 16),
              CustomTextField(
                label: AppStrings.reason,
                hint: AppStrings.enterReason,
                controller: _reasonController,
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: AppStrings.requestWithdrawal,
                onPressed: _isLoading
                    ? null
                    : () => _submitWithdrawal(effectiveSessionId),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Historial Mis retiros
        Text(
          AppStrings.myWithdrawals,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (data.withdrawals.any((w) => !w.isApproved)) ...[
          _buildPendingWithdrawalsBanner(data.withdrawals),
          const SizedBox(height: 12),
        ],
        _buildWithdrawalsList(data.withdrawals),
      ],
    );
  }

  Widget _buildTotalRecaudoLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.totalCollected,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          ),
          const SizedBox(height: 4),
          Text(
            'Dentro de sesión de caja',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Notifica cuando retiros que estaban pendientes pasan a aprobados (persiste al salir de la pantalla).
  void _checkNewlyApprovedWithdrawals(List<WithdrawalEntity> list) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final pendingIds =
          list.where((w) => !w.isApproved).map((w) => w.id).toSet();
      final previousPending =
          ref.read(previousPendingWithdrawalIdsProvider(user.id));
      final newlyApproved = list
          .where((w) => w.isApproved && previousPending.contains(w.id))
          .toList();
      if (newlyApproved.isNotEmpty) {
        final msg = newlyApproved.length == 1
            ? AppStrings.withdrawalApprovedNotification
            : AppStrings.withdrawalsApprovedCount(newlyApproved.length);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        // Volver a llamar GET /api/cash-sessions/flow/{id} para ver descuentos (total_recaudo_mostrado, saldo_disponible).
        final sessionId = newlyApproved.first.cashSessionId;
        if (sessionId.isNotEmpty) {
          ref.invalidate(cashSessionFlowProvider(sessionId));
        }
      }
      if (previousPending != pendingIds) {
        ref.read(previousPendingWithdrawalIdsProvider(user.id).notifier).state =
            pendingIds;
      }
    });
  }

  /// Alerta cuando hay retiros pendientes de aprobación.
  Widget _buildPendingWithdrawalsBanner(List<WithdrawalEntity> list) {
    final pendingCount = list.where((w) => !w.isApproved).length;
    if (pendingCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.pendingWithdrawalsAlert,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyWithdrawalsSection(
      AsyncValue<WithdrawalsDataEntity> withdrawalsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.myWithdrawals,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        withdrawalsAsync.when(
          data: (data) {
            final list = data.withdrawals;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (list.any((w) => !w.isApproved)) ...[
                  _buildPendingWithdrawalsBanner(list),
                  const SizedBox(height: 12),
                ],
                _buildWithdrawalsList(list),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error al cargar retiros: ${e.toString()}',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveSession() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.5)),
        ),
        child: Text(
          AppStrings.noActiveCashSession,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSessionContent(
    CashSessionEntity session,
    String effectiveSessionId,
    AsyncValue<WithdrawalsDataEntity> withdrawalsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSessionCards(session),
        const SizedBox(height: 24),
        Text(
          AppStrings.newWithdrawal,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: AppStrings.amount,
                hint: 'Ej: 20.000',
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
              const SizedBox(height: 16),
              CustomTextField(
                label: AppStrings.reason,
                hint: AppStrings.enterReason,
                controller: _reasonController,
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: AppStrings.requestWithdrawal,
                onPressed: _isLoading
                    ? null
                    : () => _submitWithdrawal(effectiveSessionId),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          AppStrings.myWithdrawals,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        withdrawalsAsync.when(
          data: (data) {
            final list = data.withdrawals;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (list.any((w) => !w.isApproved)) ...[
                  _buildPendingWithdrawalsBanner(list),
                  const SizedBox(height: 12),
                ],
                _buildWithdrawalsList(list),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error al cargar retiros: ${e.toString()}',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCards(CashSessionEntity? session) {
    if (session == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Sesión no encontrada',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: [
        StatCard(
          title: AppStrings.initialBalance,
          amount: session.initialBalance,
          subtitle: 'Sesión de caja',
        ),
        const SizedBox(height: 16),
        StatCard(
          title: AppStrings.withdrawal,
          amount: session.currentBalance ?? 0,
          subtitle: 'Saldo actual / Retiros',
        ),
      ],
    );
  }

  Widget _buildWithdrawalsList(List<WithdrawalEntity> list) {
    _checkNewlyApprovedWithdrawals(list);
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            AppStrings.noWithdrawals,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Column(
      children: list.map((w) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: w.isApproved
                  ? AppColors.success.withOpacity(0.5)
                  : AppColors.warning.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatter.format(w.amount),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      w.reason,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (w.createdAt != null)
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(w.createdAt!),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: w.isApproved
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  w.isApproved
                      ? AppStrings.approved
                      : AppStrings.pendingApproval,
                  style: TextStyle(
                    color: w.isApproved ? AppColors.success : AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
