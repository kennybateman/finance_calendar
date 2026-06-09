import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_calendar/data/services/database_wrapper.dart';
import 'package:finance_calendar/data/services/database_schema.dart';
import 'package:finance_calendar/data/services/database_factory.dart';

import 'package:finance_calendar/data/repositories/accounts_repository.dart';
import 'package:finance_calendar/data/repositories/bills_repository.dart';

import 'package:finance_calendar/domain/models/account.dart';
import 'package:finance_calendar/domain/models/bill.dart';
import 'package:finance_calendar/domain/use_cases/due_date.dart';

void main() async {
  late DatabaseWrapper dbWrapper;

  late AccountsRepository accountsRepo;
  late BillsRepository billsRepo;

  setUp(() async {
    final factory = getDatabaseFactory();
    dbWrapper = DatabaseWrapper(dbFileName: databaseInMemoryPath, schema: DatabaseSchema(), dbFactory: factory);

    await dbWrapper.init();

    accountsRepo = AccountsRepository(dbWrapper);
    billsRepo = BillsRepository(dbWrapper);
  });

  tearDown(() async {
    await dbWrapper.close();
  });

  group('Due date tests', () {
    late Account someAccount;
    late Bill someBill;
    late DateTime today;

    setUp(() async {
      today = toDate(DateTime.now());

      someAccount = await accountsRepo.createNew(Account(
        name: "some account", 
        balance: 101000,
        balanceDate: DateTime(today.year, today.month, 28), 
        accountType: 'debit',
      ));

      someBill = await billsRepo.createNew(Bill(
        name: "some bill", 
        amount: 5000,
        dueDate: DateTime(today.year, today.month, 15), 
        dueDateAnchorDay: 15,
        dueFrequency: "monthly", 
        payFromAccountPk: someAccount.pk,
      ));
    });

    test('Functions do what they should.', () async {
      final nextDueDate = DueDate.findNextDueDate(someBill.dueDate!, someBill.dueFrequency, someBill.dueDateAnchorDay!);
      expect(nextDueDate, DateTime(today.year, today.month + 1, 15));
      final lastDueDate = DueDate.findPriorDueDate(nextDueDate, someBill.dueFrequency, someBill.dueDateAnchorDay!);
      expect(lastDueDate, DateTime(today.year, today.month, 15));

      final farOffDueDate = DueDate.findNextDueDateAfterOrOn(DateTime(today.year, today.month + 5, 1), someBill.dueDate!, someBill.dueFrequency, someBill.dueDateAnchorDay!);
      expect(farOffDueDate, DateTime(today.year, today.month + 5, 15));
    });
  });
}