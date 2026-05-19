//import '../lib/data/repositories/projection_repository.dart';
//import 'package:finance_calendar/ui/projections/projections_page.dart';
// import 'package:finance_calendar/domain/models/account.dart';
// import 'package:finance_calendar/domain/models/bill.dart';
// import 'package:finance_calendar/domain/models/income.dart';
//import 'package:finance_calendar/domain/models/projection.dart';

//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import '../helpers/test_repositories.dart';

//import 'package:finance_calendar/main.dart';

void main() {

  group('Projection widget tests\n', () {
    /* RECORDS SET UP BY THE USER */
    // var account = Account( 
    //   name: "n", 
    //   balance: 0, 
    //   balanceDate: null, 
    //   accountType: 'debit', 
    //   creditLimit: 1000,
    //   interest: 36,
    //   dueFrequency: 'monthly',
    //   dueDate: null,
    //   payFromAccountPk: null,
    // );   
    // var bill = Bill(
    //   name: "",
    //   amount: 0,
    //   dueDate: null,
    //   dueFrequency: "",
    //   payFromAccountPk: null,
    // );
    // var bill2 = Bill(
    //   name: "",
    //   amount: 0,
    //   dueDate: null,
    //   dueFrequency: "",
    //   payFromAccountPk: null,
    // );
    // var income = Income(
    //   name: "",
    //   amount: 0,
    //   dueDate: null,
    //   dueFrequency: "",
    //   payToAccountPk: null,
    // );

    // /* RECORDS THAT WILL BE CREATED BY THE ALGORITHM */
    // var accountProjection = AccountProjection(account: account, projectedBalance: 100);
    // var billProjection = BillProjection(bill: bill, projectedAmount: 50);
    // var billProjection2 = BillProjection(bill: bill2, projectedAmount: 25);
    // var incomeProjection = IncomeProjection(income: income, projectedAmount: 500);

    // var projection = Projection(
    //   date: "11/22/63", 
    //   accountProjections: [accountProjection], 
    //   billProjections: [billProjection, billProjection2], 
    //   incomeProjections: [incomeProjection],
    // );
    // var fakeProjectionRepository = TestProjectionRepository([projection]);

    testWidgets('Projections page', (WidgetTester tester) async {

      // Build our app and trigger a frame.
      //await tester.pumpWidget(MaterialApp(home: ProjectionsPage(repo: fakeProjectionRepository)));
    });
  });
}
