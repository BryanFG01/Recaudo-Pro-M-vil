import '../entities/credit_entity.dart';
import '../entities/credit_summary_entity.dart';

abstract class CreditRepository {
  Future<List<CreditEntity>> getCredits(String businessId);
  Future<List<CreditEntity>> getCreditsByClientId(
      String businessId, String clientId);
  Future<CreditEntity?> getCreditById(String id);
  Future<CreditSummaryEntity?> getCreditSummaryById(String creditId);
  Future<List<CreditSummaryEntity>> getCreditsSummaryByUser(
      String businessId, String userId);
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
    String? cashSessionId,
  });
  Future<CreditEntity> updateCredit(
      CreditEntity credit, {String? businessId});
}

