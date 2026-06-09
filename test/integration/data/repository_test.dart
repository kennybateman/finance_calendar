// DART / FLUTTER
import 'package:flutter_test/flutter_test.dart';
// DATA
import 'package:finance_calendar/data/services/database_wrapper.dart';
import 'package:finance_calendar/data/services/database_schema.dart';
import 'package:finance_calendar/data/services/database_factory.dart';
import 'package:finance_calendar/data/repositories/accounts_repository.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/account.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/use_cases/due_date.dart';

void main() {

  late DatabaseWrapper dbWrapper;
  late AccountsRepository repo;

  setUp(() async {
    final factory = getDatabaseFactory();
    dbWrapper = DatabaseWrapper(
      dbFileName: databaseInMemoryPath, 
      schema: DatabaseSchema(), 
      dbFactory: factory
    );
    await dbWrapper.init();
    repo = AccountsRepository(dbWrapper);
  });

  tearDown(() async {
    await dbWrapper.close(); // ensures cleanup
  });

  test('Can get a domain model from the repository', () async {
    var account = Account(
      name: "some credit account", 
      balance: 1000, 
      balanceDate: toDate(DateTime.now()), 
      accountType: 'credit',
      interest: 36,
      dueDate: toDate(DateTime.now()),
      payFromAccountPk: null,
      payFromThisAccount: true, 
    );

    expect(account.pk, null);

    account = await repo.createNew(account);
    expect(account.pk, 1);
    expect(account.balanceDate, toDate(DateTime.now()));

    var all = await repo.getAll();
    expect(all.length,  1);
    expect(all.first.balanceDate, toDate(DateTime.now()));

    account = account.updateValue(balanceDate: DueDate.sameDayLastMonth(toDate(DateTime.now()), toDate(DateTime.now()).day));
    account = await repo.saveChanges(account);
    expect(account.balanceDate, DueDate.sameDayLastMonth(toDate(DateTime.now()), toDate(DateTime.now()).day));

    await repo.delete(account);

    all = await repo.getAll();
    expect(all.length,  0);
  });
}