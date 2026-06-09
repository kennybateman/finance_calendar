// DART / FLUTTER
import 'package:flutter_test/flutter_test.dart';
// DATA
import 'package:finance_calendar/data/services/database_wrapper.dart';
import 'package:finance_calendar/data/services/database_schema.dart';
import 'package:finance_calendar/data/services/database_factory.dart';
import 'package:finance_calendar/data/repositories/projections_repository.dart';
import 'package:finance_calendar/data/repositories/accounts_repository.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/projection.dart';
import 'package:finance_calendar/domain/models/account.dart';
import 'package:finance_calendar/domain/models/bill_projection.dart';
import 'package:finance_calendar/domain/models/account_projection.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

void main() {
  late DatabaseWrapper dbWrapper;
  late ProjectionsRepository projectionsRepo;
  late AccountsRepository accountsRepo;

  setUp(() async {
    final factory = getDatabaseFactory();
    dbWrapper = DatabaseWrapper(
      dbFileName: databaseInMemoryPath, 
      schema: DatabaseSchema(), 
      dbFactory: factory
    );
    await dbWrapper.init();
    projectionsRepo = ProjectionsRepository(dbWrapper);
    accountsRepo = AccountsRepository(dbWrapper);
  });

  tearDown(() async {
    await dbWrapper.close(); // ensures cleanup
  });


  group('Do projections with just a credit account\n', () {
    late Account creditAccount;

    setUp(() async {
      final today = toDate(DateTime.now());
      creditAccount = await accountsRepo.createNew(Account(
        name: "some credit account", 
        balance: 100000, 
        balanceDate: today, 
        accountType: 'credit',
        interest: 36,
        dueDate: today,
        dueDateAnchorDay: today.day,
        payFromThisAccount: true,
        ));
    });



    test('Make sure interest is applied and BillProjection saved.', () async {
      var accountProjection = AccountProjection(
        projectedBalance: 95000,
        accountPk: creditAccount.pk!,
        account: creditAccount,
      );
      var billProjection = BillProjection(
        projectedAmount: 5000, 
        creditAccountPk: creditAccount.pk,
        creditAccount: creditAccount,
      );


      var projection = Projection(date: toDate(DateTime.now()), billProjections: [billProjection], accountProjections: [accountProjection], incomeProjections: []);

      await projectionsRepo.createNewReturnVoid(projection);
      var savedProjection = await projectionsRepo.getLast();

      expect(savedProjection, isNot(null));

      expect(savedProjection!.billProjections.length, 1);
    });

  });
}