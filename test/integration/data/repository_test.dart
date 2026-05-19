import 'package:finance_calendar/data/services/database_wrapper.dart';
import 'package:finance_calendar/data/services/database_schema.dart';
import 'package:finance_calendar/data/services/database_factory.dart';

import 'package:finance_calendar/data/repositories/projections_repository.dart';
import 'package:finance_calendar/domain/models/projection.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {

  late DatabaseWrapper dbWrapper;
  late ProjectionsRepository repo;

  setUp(() async {
    final factory = getDatabaseFactory();
    dbWrapper = DatabaseWrapper(
      dbFileName: databaseInMemoryPath, 
      schema: DatabaseSchema(), 
      dbFactory: factory);
    await dbWrapper.init();
    repo = ProjectionsRepository(dbWrapper);
  });

  tearDown(() async {
    await dbWrapper.close(); // ensures cleanup
  });

  test('Can get a domain model from the repository', () async {
    var emptyProjection = Projection(date: DateTime(1963,11,22));
    expect(emptyProjection.pk, null);

    var projection = await repo.createNew(emptyProjection);
    expect(projection.pk, 1);
    expect(projection.date, '11-22-63');

    var all = await repo.getAll();
    expect(all.length,  1);
    expect(all.first.date, '11-22-63');

    var changedProjection = Projection(pk: projection.pk, date: DateTime(2001,9,11));
    var updatedProjection = await repo.saveChanges(changedProjection);
    expect(updatedProjection.date, '9-11-2001');

    await repo.delete(changedProjection);

    var all2 = await repo.getAll();
    expect(all2.length,  0);
  });
}