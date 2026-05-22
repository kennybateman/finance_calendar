import 'package:finance_calendar/data/services/database_wrapper.dart';
import 'package:finance_calendar/data/services/database_schema.dart';
import 'package:finance_calendar/data/services/database_factory.dart';

import 'package:finance_calendar/data/repositories/accounts_repository.dart';
import 'package:finance_calendar/domain/models/account.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late DatabaseWrapper dbWrapper;
  late AccountsRepository repo;

  setUp(() async {
    final factory = getDatabaseFactory();
    dbWrapper = DatabaseWrapper(dbFileName: databaseInMemoryPath, schema: DatabaseSchema(), dbFactory: factory);
    await dbWrapper.init();
    repo = AccountsRepository(dbWrapper);
  });

  tearDown(() async {
    await dbWrapper.close(); // ensures cleanup
  });


  test('Verify basic properties of Account model', () async {
    var unsavedAccount = Account(
        name: 'new account', 
        balance: 0, 
        balanceDate: null, 
        accountType: 'debit', 
        creditLimit: 0,
        interest: 0,
        dueFrequency: 'monthly',
        dueDate: null,
        payFromAccountPk: null,
      );

    expect(unsavedAccount.pk, null);

    var savedAccount = await repo.createNew(unsavedAccount);
    expect(savedAccount.pk, 1);
    expect(savedAccount.balance, 0);

    var all = await repo.getAll();
    expect(all.length,  1);
    expect(all.first.balance, 0);

    // How does the direct comparison work? And could I set up one. Should I? Nah.
    expect(all.first, isNot(savedAccount));

    var changedAccount = savedAccount.updateValue(name: 'Mother fucking account');
    var savedChangedAccount = await repo.saveChanges(changedAccount);
    expect(savedChangedAccount.name, 'Mother fucking account');

    var all2 = await repo.getAll();
    expect(all2.length,  1);
    expect(all2.first.balance, 0);
  });

  test('Verify the date type conversion into the database and back', () async {
    var account = Account(name: "a", balance: 1000, balanceDate: DateTime.now(), accountType: 'debit', );
    var savedChangedAccount = await repo.createNew(account);
    expect(savedChangedAccount.balanceDate, DateTime.now());
  });
}