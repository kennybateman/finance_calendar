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

  late Account someAccount;
  // late Account someCreditAccount;
  // late Bill someBill;
  // late Income someIncome;

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

    /* create expected records */
    someAccount = await accountsRepo.createNew(Account(
      name: "some account", 
      balance: 101000, // not used yet
      balanceDate: DateTime.now(), 
      accountType: 'debit',
      ));
    await accountsRepo.createNew(Account(
      name: "some credit account", 
      balance: 1000, 
      balanceDate: DateTime.now(), 
      accountType: 'credit',
      interest: 36,
      dueDate: DateTime.now(),
      payFromAccountPk: someAccount.pk, 
      ));
    await billsRepo.createNew(Bill(
      name: "some bill", 
      amount: 5000,
      dueDate: DateTime.now(), 
      dueFrequency: "monthly", 
      payFromAccountPk: someAccount.pk,
      ));
    await incomeRepo.createNew(Income(
      name: "some income", 
      amount: 90000,
      dueDate: DateTime.now(), 
      dueFrequency: "biweekly", 
      payToAccountPk: someAccount.pk,
      ));
  });

  tearDown(() async {
    await dbWrapper.close();
  });

  group('How to set up projection models while generating\n', () {

    test('Domain Object Graph can be set up and saved and viewed as read only models.', () async {

      await generateProjectionsUseCase.generateProjections();
      // ^expect no exception from the method above

      var readOnlyModels = await projectionsRepo.getAllReadModels();
      expect(readOnlyModels.first.accountProjectionStrings.length, 2);
      expect(readOnlyModels.first.accountProjectionStrings.first.$2, "some account: \$1718.55");

      expect(readOnlyModels.first.transactionProjectionStrings.length, 3);
      expect(readOnlyModels.first.transactionProjectionStrings[0].$3, "some credit account interest: \$141.45");
      expect(readOnlyModels.first.transactionProjectionStrings[1].$3, "some bill: \$50.00");
      expect(readOnlyModels.first.transactionProjectionStrings[2].$3, "some income: \$900.00");
    });
  });
}