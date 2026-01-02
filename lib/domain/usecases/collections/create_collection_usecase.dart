import '../../entities/collection_entity.dart';
import '../../repositories/collection_repository.dart';

class CreateCollectionUseCase {
  final CollectionRepository repository;

  CreateCollectionUseCase(this.repository);

  Future<CollectionEntity> call(CollectionEntity collection, {String? businessId}) {
    return repository.createCollection(collection, businessId: businessId);
  }
}

