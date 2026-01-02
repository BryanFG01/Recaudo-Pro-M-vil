import '../../entities/business_entity.dart';
import '../../repositories/business_repository.dart';

class GetBusinessesUseCase {
  final BusinessRepository repository;

  GetBusinessesUseCase(this.repository);

  Future<List<BusinessEntity>> call() async {
    return await repository.getBusinesses();
  }
}

