import '../../entities/credit_entity.dart';
import '../../repositories/credit_repository.dart';

class CreateCreditUseCase {
  final CreditRepository repository;

  CreateCreditUseCase(this.repository);

  Future<CreditEntity> call(CreditEntity credit, {String? businessId}) async {
    return await repository.createCredit(credit, businessId: businessId);
  }
}

