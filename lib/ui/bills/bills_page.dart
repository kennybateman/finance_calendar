// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/accounts_repository.dart';
// DOMAIN
import '../../domain/models/bill.dart';
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
// UI
import '../shared/crud_list_page.dart';
import 'edit_bill_page.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

class BillsPage extends StatelessWidget {
  final BillsRepository repo;
  final AccountsRepository accountsRepo;
  final GenerateProjectionsUseCase generateProjections;
  const BillsPage({super.key, 
    required this.repo, 
    required this.accountsRepo,
    required this.generateProjections,
  });

  @override
  Widget build(BuildContext context) {

    Widget toString(Bill bill, double scale){
      var amountString = "\$${currencyCentsToDollarsString(bill.amount)}";
      var payFromString = bill.payFromAccount != null ? "pay from: ${bill.payFromAccount!.name}" : "(missing pay from account)";
      var dueString = bill.dueDate != null ? "next due ${dateToStringForDisplay(bill.dueDate)}" : "(missing due date)";
      return Text(
        "${bill.name}: $amountString ${bill.dueFrequency} - $dueString - $payFromString",
        style: TextStyle(fontSize: 16 * scale)
      );
    }

    Bill createNewTemp(){
      return Bill(
        name: "bill", 
        amount: 0, 
        dueDate: null, 
        dueFrequency: 'monthly', 
        payFromAccountPk: null);
    }

    return CrudListPage<Bill>(
      buildTileWidget: toString,
      getAll: repo.getAll,
      useAddButton: true,
      createNewTemp: createNewTemp,
      editPage: (Bill b) => EditBillPage(bill: b, 
        generateProjections: generateProjections,
        getAllAccounts: accountsRepo.getAll,
        getAll: repo.getAll,
        createNew: repo.createNew,
        updateItem: repo.saveChanges,
        deleteItem: repo.delete,
      ),
    );
  }
}
