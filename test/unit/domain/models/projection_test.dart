// import 'package:flutter_test/flutter_test.dart';

// import 'package:finance_calendar/domain/models/account.dart';
// import 'package:finance_calendar/domain/models/bill.dart';
// //import 'package:finance_calendar/domain/models/income.dart';
// import 'package:finance_calendar/domain/models/projection.dart';

// void main() {
//   var account = Account(
//     pk: 1,
//     name: "some account", 
//     balance: 0, 
//     balanceDate: null, 
//     accountType: 'debit', 
//   );
//   var bill = Bill(
//     pk: 1,
//     name: "some bill",
//     amount: 10,
//     dueDate: DateTime.now(),
//     dueFrequency: "",
//     payFromAccountPk: 1984,
//     payFromAccount: account
//   );

//   group('How to set up projection models while generating\n', () {
//     var projection = Projection(
//       pk: 1,
//       date: DateTime.now(),
//     );
//     var accountProjection = AccountProjection(
//       pk: 1,
//       projectedBalance: 1010,
//       projectionPk: 1, 
//       projection: projection,
//       accountPk: 1, 
//       account: account);
//     var billProjection = BillProjection(
//       pk: 1,
//       projectedAmount: 10,
//       projectionPk: 1,
//       projection: projection,
//       billPk: 1,
//       bill: bill,
//     );
//     projection.addAccountProjection(accountProjection);
//     projection.addBillProjection(billProjection);
//     final projectionComplete = projection; 

//     test('Domain Object Graph can be set up and used', () async {
//       expect(projectionComplete.accountProjections.first.account!.name, "some account");
//       expect(projectionComplete.accountProjections.first.projectedBalance, 1010);

//       expect(projectionComplete.billProjections.first.bill!.name, "some bill");
//       expect(projectionComplete.billProjections.first.projectedAmount, 10);
//     });
//   });
// }