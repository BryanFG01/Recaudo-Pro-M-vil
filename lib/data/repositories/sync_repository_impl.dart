import '../../domain/entities/sync_status_entity.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/api_client.dart';
import '../datasources/client_remote_datasource.dart';
import '../datasources/collection_remote_datasource.dart';
import '../datasources/credit_remote_datasource.dart';
import '../datasources/offline_store.dart';
import '../datasources/payment_attempt_remote_datasource.dart';
import '../datasources/pending_writes_sender.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this.clients,
    required this.credits,
    required this.collections,
    required this.paymentAttempts,
    ApiClient? api,
    OfflineStore? store,
    PendingWritesSender? sender,
  })  : _api = api ?? ApiClient.instance,
        _store = store ?? OfflineStore.instance,
        _sender = sender ?? PendingWritesSender.instance;

  final ClientRemoteDataSource clients;
  final CreditRemoteDataSource credits;
  final CollectionRemoteDataSource collections;
  final PaymentAttemptRemoteDataSource paymentAttempts;
  final ApiClient _api;
  final OfflineStore _store;
  final PendingWritesSender _sender;

  @override
  bool get isOnline => _api.isOnline;

  @override
  Stream<bool> get connectivity => _api.connectivity;

  @override
  Stream<void> get queueChanges => _store.changes;

  @override
  Future<({int pending, List<RejectedWriteEntity> rejected})> queueOf(String userId) async {
    final writes = await _store.pending(userId: userId);
    return (
      pending: writes.where((w) => !w.isRejected).length,
      rejected: writes.where((w) => w.isRejected).map(_toRejected).toList(),
    );
  }

  @override
  Future<int> sync(String userId) async => (await _sender.flush(userId)).sent;

  @override
  Future<void> discard(String id) => _store.discard(id);

  @override
  Future<void> prepareOffline({required String businessId, required String userId}) async {
    try {
      // Cada lista queda guardada en el teléfono (ApiClient); de ellas salen los clientes,
      // créditos, abonos e intentos de pago que se consulten sin conexión.
      await Future.wait([
        clients.getClientsByBusiness(businessId, userId),
        credits.getCreditsByBusiness(businessId),
        collections.getCollections(businessId: businessId),
        paymentAttempts.getPaymentAttempts(businessId: businessId),
        credits.getCreditsSummaryByUser(businessId, userId),
      ]);
    } on Exception {
      // Sin conexión o error puntual: es una precarga, se usa lo que ya estaba guardado
    }
  }

  static String _labelOf(PendingWrite write) {
    if (write.resource == 'collections') return 'Cobro';
    return write.body['status'] == 'NOT_PAID' ? 'No pagó' : 'Intento de pago';
  }

  static RejectedWriteEntity _toRejected(PendingWrite write) => RejectedWriteEntity(
        id: write.id,
        label: _labelOf(write),
        amount: (write.body['amount'] as num?)?.toDouble(),
        reason: write.error ?? '',
        createdAt: write.createdAt,
      );
}
