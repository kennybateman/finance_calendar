/* SERVICE LATER */
import 'package:finance_calendar/data/services/database_wrapper.dart';
import 'package:finance_calendar/data/services/database_schema.dart';
import 'package:finance_calendar/data/services/database_factory.dart';
/* DATA LAYER */
import 'package:finance_calendar/data/models/projections_row.dart';
import 'package:finance_calendar/data/daos/projections_dao.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {

  late DatabaseWrapper dbWrapper;
  late ProjectionsDAO dao;

  setUp(() async {
    final factory = getDatabaseFactory();
    dbWrapper = DatabaseWrapper(
      dbFileName: databaseInMemoryPath, 
      schema: DatabaseSchema(), 
      dbFactory: factory);
    await dbWrapper.init();
    dao = ProjectionsDAO(dbWrapper: dbWrapper);
  });

  tearDown(() async {
    await dbWrapper.close(); // ensures cleanup
  });


  test('Can perform basic operations', () async {

    // unsaved tmp version of model
    var tmpRow = ProjectionsRow(pk: null, date: '11-22-63');
    expect(tmpRow.pk, null); // has no pk

    // save the temp model via the db
    await dao.create(tmpRow);
    var results = await dao.getAll();

    // saved version of model
    var savedRow = results.first;
    expect(savedRow.pk, 1); // has a pk
    expect(savedRow.date, '11-22-63'); // same value we created it with

    // // unsaved modified copy of model
    var changedRow = ProjectionsRow(pk: savedRow.pk, date: '9-11-2001'); // change date

    // updating should return the same result
    var result = await dao.update(changedRow);
    expect(result.date, '9-11-2001');
    var results2 = await dao.getAll();
    expect(results2.first.date, '9-11-2001'); // be sure to check this too

    // finally, remove it from the database
    await dao.delete(result);
    var results3 = await dao.getAll();
    expect(results3.length, 0); // db is now empty
  });
}