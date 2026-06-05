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
//import 'package:finance_calendar/domain/models/projection.dart';
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
    generateProjectionsUseCase = GenerateProjectionsUseCase(accountsRepo, billsRepo, incomeRepo, projectionsRepo);
  });

  tearDown(() async {
    await dbWrapper.close();
  });

  group('How to set up projection models while generating\n', () {
    late Account someAccount;

    setUp(() async {
      final today = toDate(DateTime.now());
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

    test('Domain Object Graph can be set up and saved and viewed as read only models.', () async {
      await generateProjectionsUseCase.generateProjections();
      var readOnlyModels = await projectionsRepo.getAll();
      expect(readOnlyModels.first.accountProjectionStrings.length, 2);
      expect(readOnlyModels.first.accountProjectionStrings.first, "some account: \$1699.09");

      expect(readOnlyModels.first.transactionProjectionStrings.length, 3);
      expect(readOnlyModels.first.transactionProjectionStrings[0], "some credit account interest: \$160.91");
      expect(readOnlyModels.first.transactionProjectionStrings[1], "some bill: \$50.00");
      expect(readOnlyModels.first.transactionProjectionStrings[2], "some income: \$900.00");
    });
  });

  /* 
    Here I want to test catching up the dates on bills or accounts.
  */
  group('Test individual components of the projection generation.', () {
    late Account someAccount;
    late DateTime endOfMay;

    setUp(() async {
      endOfMay = DateTime(2026, 5, 31);

      final endOfApril = sameDayLastMonth(endOfMay, endOfMay.day);

      /* theoretically test somehwere else, but this is a nice sanity check */
      expect(endOfApril, DateTime(2026, 4, 30));

      /* create expected records */
      someAccount = await accountsRepo.createNew(Account(
        name: "some account", 
        balance: 101000, // not used yet
        balanceDate: endOfMay, 
        accountType: 'debit',
        ));

      /* set up the due date one month before to make sure it catches up */
      await billsRepo.createNew(Bill(
        name: "some bill", 
        amount: 5000,
        dueDate: endOfApril, 
        dueDateAnchorDay: endOfMay.day, // use end of may as anchor date
        dueFrequency: "monthly", 
        payFromAccountPk: someAccount.pk,
        ));
    });
    

    /* Conclusion about how the financial world handles billing is that if you sign up on a day of the month
      Then your bill is always due on that day of the month, unless that month doesn't have that day, then it is clamped
      to the last available day in the month. This gives the illusion of reverse clamping if you only track the dates
      incrementally. Thus I need to preserve and achor date. Thus I shouldn't be incrementing these the actual account due
      dates at all.
    */
    test('Due date should have been caught up independent of projection succeeding.', () async {
      await generateProjectionsUseCase.loadAndValidateAllRecords();
      await generateProjectionsUseCase.catchUpDueDates();

      final bills = await billsRepo.getAll();
      expect(bills[0].dueDate, endOfMay);
    });



    test('Due date should have been caught up, and deducted bill from account.', () async {
      await generateProjectionsUseCase.generateProjections();
      var readOnlyModels = await projectionsRepo.getAll();

      expect(readOnlyModels.first.accountProjectionStrings.length, 1);
      /* THIS CURRENTLY FAILS */
      expect(readOnlyModels.first.accountProjectionStrings.first, "some account: \$960.00");

      expect(readOnlyModels.first.transactionProjectionStrings.length, 1);
      expect(readOnlyModels.first.transactionProjectionStrings[0], "some bill: \$50.00");
    });
  });


}