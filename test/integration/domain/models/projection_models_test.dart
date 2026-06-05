// import 'package:flutter_test/flutter_test.dart';

// import 'package:finance_calendar/data/services/database_wrapper.dart';
// import 'package:finance_calendar/data/services/database_schema.dart';
// import 'package:finance_calendar/data/services/database_factory.dart';

// import 'package:finance_calendar/data/repositories/accounts_repository.dart';
// import 'package:finance_calendar/data/repositories/bills_repository.dart';
// import 'package:finance_calendar/data/repositories/income_repository.dart';
// import 'package:finance_calendar/data/repositories/projections_repository.dart';

// import 'package:finance_calendar/domain/models/account.dart';
// import 'package:finance_calendar/domain/models/bill.dart';
// import 'package:finance_calendar/domain/models/income.dart';
// import 'package:finance_calendar/domain/models/projection.dart';

// void main() async {
//   late DatabaseWrapper dbWrapper;

//   late ProjectionsRepository projectionsRepo;
//   late AccountsRepository accountsRepo;
//   late BillsRepository billsRepo;
//   late IncomeRepository incomeRepo;

//   late Account someAccount;
//   late Account someCreditAccount;
//   late Bill someBill;
//   late Income someIncome;

//   setUp(() async {
//     /* set up db */
//     final factory = getDatabaseFactory();
//     dbWrapper = DatabaseWrapper(dbFileName: databaseInMemoryPath, schema: DatabaseSchema(), dbFactory: factory);
//     await dbWrapper.init();

//     /* initialize repos */
//     projectionsRepo = ProjectionsRepository(dbWrapper);
//     accountsRepo = AccountsRepository(dbWrapper);
//     billsRepo = BillsRepository(dbWrapper);
//     incomeRepo = IncomeRepository(dbWrapper);

//     /* expected records */
//     someAccount = await accountsRepo.createNew(Account(name: "some account", 
//       balance: 0, // not used yet
//       balanceDate: null, accountType: 'debit'));
//     someCreditAccount = await accountsRepo.createNew(Account(name: "some credit account", 
//       balance: 1000, interest: 36,
//       balanceDate: null, accountType: 'credit'));
//     someBill = await billsRepo.createNew(Bill(name: "some bill", 
//       amount: 0, // not used yet
//       dueDate: DateTime.now(), dueFrequency: "monthly", payFromAccountPk: someAccount.pk));
//     someIncome = await incomeRepo.createNew(Income(name: "some income", 
//       amount: 0, // not used yet
//       dueDate: DateTime.now(), dueFrequency: "monthly", payToAccountPk: someAccount.pk));
//   });

//   tearDown(() async {
//     await dbWrapper.close();
//   });



//   group('How to set up projection models while generating\n', () {

//     test('Domain Object Graph can be set up and saved and viewed as read only models.', () async {
//       var projection = Projection(date: DateTime.now());
//       var accountProjection = AccountProjection(projectedBalance: 101000, accountPk: someAccount.pk!);
//       var billProjection = BillProjection(projectedAmount: 1000, billPk: someBill.pk!);
//       var interestBillProjection = BillProjection(projectedAmount: 3300, creditAccountPk: someCreditAccount.pk);
//       var incomeProjection = IncomeProjection(projectedAmount: 50000, incomePk: someIncome.pk!);
//       projection.addAccountProjection(accountProjection);
//       projection.addBillProjection(billProjection);
//       projection.addBillProjection(interestBillProjection);
//       projection.addIncomeProjection(incomeProjection);

//       await projectionsRepo.createNewReturnVoid(projection);
//       // ^expect no exception from the method above

//       var readOnlyModels = await projectionsRepo.getAllReadModels();
//       expect(readOnlyModels.first.accountProjectionStrings().length, 1);
//       expect(readOnlyModels.first.accountProjectionStrings().first, "some account: \$1010.00");

//       expect(readOnlyModels.first.transactionProjectionStrings().length, 3);
//       expect(readOnlyModels.first.transactionProjectionStrings()[0], "some bill: \$10.00");
//       expect(readOnlyModels.first.transactionProjectionStrings()[2], "some income: \$500.00");
//       expect(readOnlyModels.first.transactionProjectionStrings()[1], "some credit account interest: \$33.00");
//     });
//   });
// }