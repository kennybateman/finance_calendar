// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/accounts_repository.dart';
// DOMAIN
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
import '../../domain/models/income.dart';
import '../../domain/models/abstract_domain_model.dart';
// UI
import '../shared/crud_list_page.dart';
import 'edit_income_page.dart';

class IncomePage extends StatelessWidget {
  final IncomeRepository repo;
  final AccountsRepository accountsRepo;
  final GenerateProjectionsUseCase generateProjections;
  const IncomePage({super.key, 
    required this.repo, 
    required this.accountsRepo,
    required this.generateProjections,
  });

  @override
  Widget build(BuildContext context) {

    Widget toString(Income income, double scale){
      var amountString = "\$${currencyCentsToDollarsString(income.amount)}";
      var payToString = income.payToAccount != null ? "pay to: ${income.payToAccount!.name}" : "(missing pay to account)";
      var dueString = income.dueDate != null ? "next due ${dateToStringForDisplay(income.dueDate)}" : "(missing due date)";
      return Text(
        "${income.name}: $amountString ${income.dueFrequency} - $dueString - $payToString",
        style: TextStyle(fontSize: 16 * scale)
      );
    }

    Future<List<Income>> joinExtraModels(List<Income> unjoinedIncome) async {
      var allAccounts = await accountsRepo.getAll();
      var accountsbyPk = mapByPk(allAccounts);
      return unjoinedIncome.map((i) => i.joinPayToAccount(accountsbyPk[i.payToAccountPk])).toList();
    }

    return CrudListPage<Income>(
      buildTileWidget: toString,
      getAll: repo.getAll,
      createNew: repo.createNew,
      updateItem: repo.saveChanges,
      deleteItem: repo.delete,
      joinExtraModels: joinExtraModels,

      createEmpty: () => Income.createNewTemp(),
      editPage: (Income i) => EditIncomePage(income: i, 
        generateProjections: generateProjections,
        getAllAccounts: accountsRepo.getAll,
        getAllIncome: repo.getAll,
        createNew: repo.createNew,
        updateItem: repo.saveChanges,
        deleteItem: repo.delete,
      ),
      useAddButton: true,
    );
  }
}
