import 'package:finance_calendar/data/services/database_wrapper.dart';
import 'package:finance_calendar/data/services/database_schema.dart';
import 'package:finance_calendar/data/services/database_factory.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {

  late DatabaseWrapper dbWrapper;

  setUp(() async {
    final factory = getDatabaseFactory();
    dbWrapper = DatabaseWrapper(dbFileName: databaseInMemoryPath, schema: DatabaseSchema(), dbFactory: factory);
    await dbWrapper.init();
  });

  tearDown(() async {
    await dbWrapper.close(); // ensures cleanup
  });

  test('Can add to and read from the database', () async {
    await dbWrapper.database.rawQuery(
      '''
        INSERT INTO projections (date)
        VALUES ('2026-01-01');
      '''
    );
    var result = await dbWrapper.database.rawQuery(
      '''
        SELECT COUNT(*) FROM projections;
      '''
    );
    expect(result.first.values.first, 1);
  });

  test('Can read different value types from the database', () async {
    await dbWrapper.database.rawQuery(
      '''
        INSERT INTO bills (name, amount, due_date, due_frequency, pay_from_account_pk)
        VALUES ('some bill', 5000, '2026-01-01', 'monthly', 1);
      '''
    );
    var result = await dbWrapper.database.rawQuery(
      '''
        SELECT * FROM bills LIMIT 1;
      '''
    );
    expect(result.first['pk'] is int, true);               // INTEGER -> int
    expect(result.first['name'] is String, true);          // TEXT -> String
    expect(result.first['amount'] is int, true);        // INTEGER -> double
    expect(result.first['due_date'] is String, true);      // SQLite doesn't have dates, we use TEXT
    expect(result.first['pay_from_account_pk'] is int, true); // FOREIGN KEYS are INTEGER -> int
  });
}