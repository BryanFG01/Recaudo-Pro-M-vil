import '../../entities/credit_entity.dart';
import '../../repositories/credit_repository.dart';

class GetCreditsUseCase {
  final CreditRepository repository;

  GetCreditsUseCase(this.repository);

  Future<List<CreditEntity>> call(String businessId) {
    return repository.getCredits(businessId);
  }
}

