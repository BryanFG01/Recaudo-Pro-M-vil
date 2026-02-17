import 'package:flutter/foundation.dart';

import '../../domain/entities/credit_entity.dart';
import '../../domain/entities/credit_summary_entity.dart';
import '../../domain/repositories/credit_repository.dart';
import '../datasources/credit_remote_datasource.dart';

class CreditRepositoryImpl implements CreditRepository {
  final CreditRemoteDataSource remoteDataSource;

  CreditRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CreditEntity>> getCredits(String businessId) {
    return remoteDataSource.getCreditsByBusiness(businessId);
  }

  @override
  Future<List<CreditEntity>> getCreditsByClientId(
      String businessId, String clientId) async {
    debugPrint('getCreditsByClientId - businessId: $businessId, clientId: $clientId');
    final all = await remoteDataSource.getCreditsByBusiness(businessId);
    debugPrint('getCreditsByClientId - Total credits for business: ${all.length}');
    final filtered = all.where((c) => c.clientId == clientId).toList();
    debugPrint('getCreditsByClientId - Filtered credits for client: ${filtered.length}');
    if (filtered.isEmpty && all.isNotEmpty) {
      debugPrint('getCreditsByClientId - Client IDs in all credits:');
      for (final c in all.take(5)) {
        debugPrint('  - Credit ${c.id}: client_id = ${c.clientId}');
      }
    }
    return filtered;
  }

  @override
  Future<CreditEntity?> getCreditById(String id) {
    return remoteDataSource.getCreditById(id);
  }

  @override
  Future<CreditSummaryEntity?> getCreditSummaryById(String creditId) {
    return remoteDataSource.getCreditSummaryById(creditId);
  }

  @override
  Future<List<CreditSummaryEntity>> getCreditsSummaryByUser(
      String businessId, String userId) {
    return remoteDataSource.getCreditsSummaryByUser(businessId, userId);
  }

  @override
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
    String? cashSessionId,
  }) {
    return remoteDataSource.createCredit(
      credit,
      businessId: businessId,
      businessCode: businessCode,
      userNumber: userNumber,
      documentId: documentId,
      cashSessionId: cashSessionId,
    );
  }

  @override
  Future<CreditEntity> updateCredit(
    CreditEntity credit, {
    String? businessId,
    String? userNumber,
    String? documentId,
  }) {
    return remoteDataSource.updateCredit(
      credit,
      businessId: businessId,
      userNumber: userNumber,
      documentId: documentId,
    );
  }
}
