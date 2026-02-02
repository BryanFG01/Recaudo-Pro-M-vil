import '../../entities/client_entity.dart';
import '../../repositories/client_repository.dart';

class CreateClientUseCase {
  final ClientRepository repository;

  CreateClientUseCase(this.repository);

  Future<ClientEntity> call(
    ClientEntity client, {
    String? businessId,
    String? businessCode,
    String? userId,
    String? userNumber,
  }) async {
    return await repository.createClient(
      client,
      businessId: businessId,
      businessCode: businessCode,
      userId: userId,
      userNumber: userNumber,
    );
  }
}

