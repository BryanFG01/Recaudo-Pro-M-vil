import '../../entities/credit_entity.dart';
import '../../repositories/credit_repository.dart';

class CreateCreditUseCase {
  final CreditRepository repository;

  CreateCreditUseCase(this.repository);

  Future<CreditEntity> call(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
  }) async {
    return await repository.createCredit(
      credit,
      businessId: businessId,
      businessCode: businessCode,
      userNumber: userNumber,
      documentId: documentId,
    );
  }
}

