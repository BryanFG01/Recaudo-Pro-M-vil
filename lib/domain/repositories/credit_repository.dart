import '../entities/credit_entity.dart';

abstract class CreditRepository {
  Future<List<CreditEntity>> getCredits();
  Future<List<CreditEntity>> getCreditsByClientId(String clientId);
  Future<CreditEntity?> getCreditById(String id);
  Future<CreditEntity> createCredit(CreditEntity credit, {String? businessId});
  Future<CreditEntity> updateCredit(CreditEntity credit, {String? businessId});
}

