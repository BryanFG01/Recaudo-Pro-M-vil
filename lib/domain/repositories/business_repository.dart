import '../entities/business_entity.dart';

abstract class BusinessRepository {
  Future<List<BusinessEntity>> getBusinesses();
  Future<List<BusinessEntity>> searchBusinesses(String query);
  Future<BusinessEntity?> getBusinessByCode(String code);
  Future<BusinessEntity?> getBusinessById(String id);
}

