// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/accounts_repository.dart';
import '../../data/repositories/settings_repository.dart';
// DOMAIN
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
import '../../domain/models/account.dart';
import '../../domain/use_cases/due_date.dart';
// UI
import '../shared/crud_list_page.dart';
import 'edit_account_page.dart';

class AccountsPage extends StatelessWidget {
  final AccountsRepository repo;
  final GenerateProjectionsUseCase generateProjections;
  final SettingsRepository settingsRepo;
  const AccountsPage({super.key, 
    required this.repo,
    required this.generateProjections,
    required this.settingsRepo,
  });

  @override
  Widget build(BuildContext context) {

    Widget toString(Account account, double scale){ 
      /* Common fields */
      String balanceString = "\$${currencyCentsToDollarsString(account.balance)}";
      String lastReportedString = account.balanceDate != null ? "last reported ${dateToStringForDisplay(account.balanceDate!)!}" : "(no date set)";
      String content;
      /* Credit only fields */
      if(account.accountType == "credit"){
        // General credit account into
        final creditLimitString = "of \$${currencyCentsToDollarsString(account.creditLimit)}";
        final creditInterestString = "at ${currencyCentsToDollarsString(account.interest)}%/yr";
        // Interest payments
        final amountString = account.dueDate != null ? "\$${currencyCentsToDollarsString(calculateCompoundInterest(account.balance, account.dueDate!))}" : "";
        
        final String dueDateString;
        if (account.dueDate != null && account.dueDateAnchorDay != null){
          final nextDueDate = DueDate.findNextDueDateAfterOrOn(
            toDate(DateTime.now()), 
            account.dueDate!, 
            account.dueFrequency, 
            account.dueDateAnchorDay!
          );
          dueDateString = "due ${dateToStringForDisplay(nextDueDate)}";
        }
        else{
          dueDateString = "(missing due date)";
        }

        final payFromString = account.payFromAccount != null ? "pay from: ${account.payFromAccount!.name}" : "(missing pay to account)";

        final accountInfoString = "$creditLimitString $creditInterestString";
        final nextInterestPaymentString = "$amountString $dueDateString - $payFromString";

        content = "${account.name}: $balanceString $lastReportedString $accountInfoString - $nextInterestPaymentString";
      }
      else {
       content = "${account.name}: $balanceString $lastReportedString";
      }
      return Text(
        content, 
        style: TextStyle(fontSize: 16 * scale)
      );
    }

    Account createNewTemp(){
      return Account(
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
    }

    return CrudListPage<Account>(
      settingsRepo: settingsRepo,
      buildTileWidget: toString,
      getAll: repo.getAll,
      useAddButton: true,
      createNewTemp: createNewTemp,
      editPage: (Account a) => EditAccountPage(account: a, 
        generateProjections: generateProjections,
        getAll: repo.getAll, 
        createNew: repo.createNew,
        updateItem: repo.saveChanges,
        deleteItem: repo.delete,
      ),
    );
  }
}
