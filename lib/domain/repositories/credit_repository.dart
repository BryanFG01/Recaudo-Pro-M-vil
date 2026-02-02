import '../entities/credit_entity.dart';

abstract class CreditRepository {
  Future<List<CreditEntity>> getCredits(String businessId);
  Future<List<CreditEntity>> getCreditsByClientId(
      String businessId, String clientId);
  Future<CreditEntity?> getCreditById(String id);
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
  });
  Future<CreditEntity> updateCredit(
      CreditEntity credit, {String? businessId});
}

