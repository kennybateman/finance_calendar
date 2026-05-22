// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/accounts_repository.dart';
// DOMAIN
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
import '../../domain/models/income.dart';
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

    Widget buildTileWidget(Income income, double scale){
      var amountString = "\$${currencyCentsToDollarsString(income.amount)}";
      var payToString = income.payToAccount != null ? "pay to: ${income.payToAccount!.name}" : "(missing pay to account)";
      var dueString = income.dueDate != null ? "next due ${dateToStringForDisplay(income.dueDate)}" : "(missing due date)";
      return Text(
        "${income.name}: $amountString ${income.dueFrequency} - $dueString - $payToString",
        style: TextStyle(fontSize: 16 * scale)
      );
    }

    Income createNewTemp(){
      return Income(
        name: "income", 
        amount: 0, 
        dueDate: null, 
        dueFrequency: 'biweekly', 
        payToAccountPk: null);
    }

    return CrudListPage<Income>(
      getAll: repo.getAll,
      buildTileWidget: buildTileWidget,
      useAddButton: true,
      createNewTemp: createNewTemp,
      editPage: (Income i) => EditIncomePage(income: i, 
        generateProjections: generateProjections,
        getAccountNames: accountsRepo.getAllNames,
        getIncomeNames: repo.getAllNames,
        createNew: repo.createNew,
        updateItem: repo.saveChanges,
        deleteItem: repo.delete,
      ),
    );
  }
}
