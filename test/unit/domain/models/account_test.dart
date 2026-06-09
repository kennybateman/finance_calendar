import 'package:finance_calendar/domain/models/account.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Projection tests\n', () {
    var account = Account( 
      name: "n", 
      balance: 0, 
      balanceDate: null, 
      accountType: 'debit', 
      creditLimit: 1000,
      interest: 36,
      dueFrequency: 'monthly',
      dueDate: null,
      payFromAccountPk: null,
    );
    var account2 = Account( 
      name: "n", 
      balance: 0, 
      balanceDate: null, 
      accountType: 'debit', 
      creditLimit: 1000,
      interest: 36,
      dueFrequency: 'monthly',
      dueDate: null,
      payFromAccountPk: null,
    );

    test('Projection model instantiates', () async {
      expect(account, account2);
    });
  });
}