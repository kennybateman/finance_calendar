//import 'package:finance_calendar/data/repositories/projection_repository.dart';
import 'package:finance_calendar/data/repositories/abstract_repository.dart';
import 'package:finance_calendar/domain/models/projection.dart';
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';
// import 'package:finance_calendar/data/models/data_abstraction_object.dart';
// import 'package:finance_calendar/data/services/database_wrapper.dart';
// import 'package:finance_calendar/domain/models/projection.dart';

class TestRepository<T extends DomainModel<T>> implements Repository<T> {
  final List<T> models;

  TestRepository([List<T>? initial]) : models = initial ?? [];

  @override
  Future<T> createNew(T tmpItem) async {
    models.add(tmpItem);
    return tmpItem;
  }

  @override
  Future<List<T>> getAll() async {
    return List.unmodifiable(models);
  }

  @override
  Future<T> saveChanges(T itemWithChanges) async {
    final index = models.indexOf(itemWithChanges);
    if (index != -1) {
      models[index] = itemWithChanges;
    }
    return itemWithChanges;
  }

  @override
  Future<void> delete(T itemToDelete) async {
    models.remove(itemToDelete);
  }
}

class TestProjectionRepository extends TestRepository<Projection>{
  TestProjectionRepository(List<Projection> models);
}