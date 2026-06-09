import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_calendar/data/services/database_wrapper.dart';
import 'package:finance_calendar/data/services/database_schema.dart';
import 'package:finance_calendar/data/services/database_factory.dart';

import 'package:finance_calendar/data/repositories/accounts_repository.dart';
import 'package:finance_calendar/data/repositories/bills_repository.dart';
import 'package:finance_calendar/data/repositories/income_repository.dart';
import 'package:finance_calendar/data/repositories/projections_repository.dart';

import 'package:finance_calendar/domain/models/account.dart';
import 'package:finance_calendar/domain/models/bill.dart';
import 'package:finance_calendar/domain/models/income.dart';
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';

void main() async {
  late DatabaseWrapper dbWrapper;

  late ProjectionsRepository projectionsRepo;
  late AccountsRepository accountsRepo;
  late BillsRepository billsRepo;
  late IncomeRepository incomeRepo;

  late GenerateProjectionsUseCase generateProjectionsUseCase;

  setUp(() async {
    /* set up db */
    final factory = getDatabaseFactory();
    dbWrapper = DatabaseWrapper(dbFileName: databaseInMemoryPath, schema: DatabaseSchema(), dbFactory: factory);

    await dbWrapper.init();

    /* initialize repos */
    projectionsRepo = ProjectionsRepository(dbWrapper);
    accountsRepo = AccountsRepository(dbWrapper);
    billsRepo = BillsRepository(dbWrapper);
    incomeRepo = IncomeRepository(dbWrapper);

    /* pass repos to Generate Projections */
    generateProjectionsUseCase = GenerateProjectionsUseCase(accountsRepo, billsRepo, incomeRepo, projectionsRepo, 27); // just shy of any month
  });

  tearDown(() async {
    await dbWrapper.close();
  });

  group('How to set up projection models while generating\n', () {
    late Account someAccount;
    late DateTime today;

    setUp(() async {
      today = toDate(DateTime.now());
      someAccount = await accountsRepo.createNew(Account(
        name: "some account", 
        balance: 101000, // not used yet
        balanceDate: today, 
        accountType: 'debit',
        ));
      await accountsRepo.createNew(Account(
        name: "some credit account", 
        balance: 1000, 
        balanceDate: today, 
        accountType: 'credit',
        interest: 36,
        dueDate: today,
        dueDateAnchorDay: today.day,
        payFromAccountPk: someAccount.pk, 
        ));
      await billsRepo.createNew(Bill(
        name: "some bill", 
        amount: 5000,
        dueDate: today, 
        dueDateAnchorDay: today.day,
        dueFrequency: "monthly", 
        payFromAccountPk: someAccount.pk,
        ));
      await incomeRepo.createNew(Income(
        name: "some income", 
        amount: 90000,
        dueDate: today, 
        dueDateAnchorDay: today.day,
        dueFrequency: "biweekly", 
        payToAccountPk: someAccount.pk,
        ));
    });

    test('Domain Object Graph can be set up and saved and read.', () async {
      await generateProjectionsUseCase.generateInitialProjections();
      var projections = await projectionsRepo.getAll();
      expect(projections.first.accountProjectionStrings.length, 2);
      //expect(projections.first.accountProjectionStrings.first, "some account: \$1689.82"); interest won't be be consistent

      expect(projections.first.transactionProjectionStrings.length, 3);
      expect(projections.first.transactionProjectionStrings[0], "some income: \$900.00");
      //expect(projections.first.transactionProjectionStrings[1], "some credit account interest: \$170.18"); // interest won't be consistent
      expect(projections.first.transactionProjectionStrings[2], "some bill: \$50.00"); 

      await generateProjectionsUseCase.generateMoreProjections();
      var projectionsAndMore = await projectionsRepo.getAll();

      expect(projectionsAndMore.length, 54);
      var moreProjectionsDueDate = await projectionsRepo.getForDate(DateTime(today.year, today.month+1, today.day));

      expect(moreProjectionsDueDate, isNot(null));
      expect(moreProjectionsDueDate!.transactionAmounts.length, 2);
    });
  });
}