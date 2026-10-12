import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_format.dart';
import '../../domain/entities/sync_status_entity.dart';
import '../providers/sync_provider.dart';
import '../routes/app_router.dart';

enum SyncBannerTone { offline, syncing, rejected }

/// Texto y tono del aviso según el estado (función pura, con tests).
({String text, SyncBannerTone tone}) syncBannerMessage(SyncStatusEntity status) {
  final rejected = status.rejected.length;
  if (rejected > 0) {
    final what = rejected == 1 ? '1 registro no se pudo enviar' : '$rejected registros no se pudieron enviar';
    return (text: '$what · Toca para revisar', tone: SyncBannerTone.rejected);
  }
  final pending = status.pending == 1 ? '1 pendiente' : '${status.pending} pendientes';
  if (!status.isOnline) {
    final detail = status.pending > 0 ? '$pending por enviar' : 'Mostrando los últimos datos guardados';
    return (text: 'Sin conexión · $detail', tone: SyncBannerTone.offline);
  }
  return (text: 'Enviando $pending…', tone: SyncBannerTone.syncing);
}

/// Pone el aviso de conexión arriba de todas las pantallas cuando hace falta.
class SyncBannerLayout extends ConsumerWidget {
  final Widget child;
  const SyncBannerLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(syncStatusProvider.select((s) => s.isVisible));
    if (!isVisible) return child;
    return Column(
      children: [
        const _SyncBanner(),
        // El aviso ya ocupa la zona de la barra de estado
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ],
    );
  }
}

class _SyncBanner extends ConsumerWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final message = syncBannerMessage(status);
    final (background, foreground, icon) = switch (message.tone) {
      SyncBannerTone.rejected => (AppColors.error, AppColors.paper, Icons.error_outline),
      SyncBannerTone.offline => (AppColors.graphite, AppColors.paper, Icons.cloud_off_outlined),
      SyncBannerTone.syncing => (AppColors.primary, AppColors.onPrimary, Icons.cloud_upload_outlined),
    };
    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () => _onTap(ref, status),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Expanded(child: Text(message.text, style: TextStyle(color: foreground, fontSize: 13))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(WidgetRef ref, SyncStatusEntity status) {
    if (status.rejected.isEmpty) {
      ref.read(syncStatusProvider.notifier).syncNow();
      return;
    }
    // El aviso está por encima del Navigator: el diálogo se abre con el contexto del router
    final navigatorContext = ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    showDialog<void>(context: navigatorContext, builder: (_) => const _RejectedWritesDialog());
  }
}

class _RejectedWritesDialog extends ConsumerWidget {
  const _RejectedWritesDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejected = ref.watch(syncStatusProvider.select((s) => s.rejected));
    return AlertDialog(
      title: const Text('Registros no enviados'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('El servidor rechazó estos registros hechos sin conexión. Revísalos con el '
                'administrador y vuelve a registrarlos si corresponde.'),
            const SizedBox(height: 12),
            for (final write in rejected) _RejectedWriteTile(write: write),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}

class _RejectedWriteTile extends ConsumerWidget {
  final RejectedWriteEntity write;
  const _RejectedWriteTile({required this.write});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = write.amount == null ? '' : ' · ${AppCurrency.format(write.amount!)}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${write.label}$amount'),
      subtitle: Text(write.reason),
      trailing: TextButton(
        onPressed: () => ref.read(syncStatusProvider.notifier).discard(write.id),
        child: const Text('Descartar'),
      ),
    );
  }
}
