import '../../domain/models/abstract_domain_model.dart';

abstract class Repository<T extends DomainModel> {
  Future<T> createNew(T item);
  Future<List<T>> getAll();
  Future<T> saveChanges(T itemWithChanges);
  Future<void> delete(T itemToDelete);
}
