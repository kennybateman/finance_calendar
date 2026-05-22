// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import '../../domain/models/income.dart';
import '../../domain/use_cases/helpers.dart';
import '../../domain/use_cases/edit_exception.dart';
import '../../domain/use_cases/generate_projections.dart';
import '../../domain/models/account.dart';
// UI
import '../shared/date_form_input.dart';
import '../shared/select_form_input.dart';
import '../shared/text_form_input.dart';
import '../shared/crud_edit_page.dart';

class EditIncomePage extends StatefulWidget{
  final GenerateProjectionsUseCase generateProjections;
  final Future<List<Account>> Function() getAllAccounts;
  final Future<List<Income>>  Function() getAllIncome;
  final Future<Income>        Function(Income) createNew;  // C
  final Income income;                                     // R (bill being edited)
  final Future<Income>        Function(Income) updateItem; // U
  final Future<void>          Function(Income) deleteItem; // D
  const EditIncomePage({super.key, 
    required this.generateProjections,
    required this.income,
    required this.getAllAccounts,
    required this.getAllIncome,
    required this.createNew,
    required this.updateItem,
    required this.deleteItem,
  });

  @override
  State<EditIncomePage> createState() => EditIncomePageState();
}

class EditIncomePageState extends State<EditIncomePage> {
  late TextEditingController nameController;
  late TextEditingController amountController;
  late DateTime? dueDate;
  late String dueFrequency;
  late int? payToAccountPk;
  /* need access to all accounts ot allow changing pay from account */
  late List<Account> allAccounts;
  late List<String> accountNames = ['loading']; // display account names for the selection
  late Map<int?, Account?> accountsByPk = { null: null };
  /* need access to all income to enforce name uniqueness */
  late List<Income> allIncome;

  static const String deselectAccountString = '';

  @override
  void initState() {
    super.initState();
    incomeToForm(widget.income);
    getAllAccounts(); // asynchronous call
    getAllIncome(); // asynchronous call
  }

  void incomeToForm(Income income){
    nameController = TextEditingController(text: income.name);
    amountController = TextEditingController(text: currencyCentsToDollarsString(income.amount));
    dueFrequency = income.dueFrequency;
    payToAccountPk = income.payToAccountPk;
    dueDate = income.dueDate;
  }

  void getAllAccounts() async {
    final accounts = await widget.getAllAccounts();

    var newAccountNames = [ deselectAccountString ] + accounts.map((a) => a.name).toList();

    Map<int?, Account?> newAccountsByPk = {};
    for(var account in accounts){
      newAccountsByPk[account.pk] = account;
    }

    setState((){
      allAccounts = accounts;
      accountNames = newAccountNames;
      accountsByPk = newAccountsByPk;
    });
  }

  void getAllIncome() async {
    final income = await widget.getAllIncome();
    setState((){
      allIncome = income;
    });
  }

  void validateInput() {
    /* Database doesn't allow same names. Don't rely on that though. Catch it here */
    final newName = nameController.text;
    for(var income in allIncome){
      /* allIncome all have pks, widget.income might not, either way, we are allowed to change the name */
      if (income.pk == widget.income.pk) continue;
      if (newName == income.name){
        throw EditException("Existing Income already uses this name");
      }
    }
  }

  Income formToIncome() {
    validateInput();
    return Income(
      pk: widget.income.pk,
      name: nameController.text,
      amount: dollarsStringToCurrencyCents(amountController.text),
      dueFrequency: dueFrequency,
      payToAccountPk: payToAccountPk,
      dueDate: dueDate,
    );
  }

  void onDueDateChange(DateTime date){
    setState((){
      dueDate = date;
    });
  }

  void payToAccountChanged(String selectedAccountName){
    int? newPk;

    if (selectedAccountName == deselectAccountString){
      newPk = null;
    }
    else{
      newPk = allAccounts.firstWhere((a) => a.name == selectedAccountName).pk;
    }

    setState((){
      payToAccountPk = newPk;
    });
  }

  void dueFrequencyChanged(String value){
    setState(() {
      dueFrequency = value;
    });
  }

  List<Widget> generateUniqueInputs(){
    return [
      TextFormInput("Name", nameController),
      TextFormInput("Amount", amountController),
      DateFormInput("Due date", dueDate, onDueDateChange),
      SelectFormInput("Frequency", ['monthly', 'bimonthly', 'weekly', 'biweekly'], dueFrequency, dueFrequencyChanged),
      SelectFormInput("Pay to", accountNames, accountsByPk[payToAccountPk]?.name, payToAccountChanged),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CrudEditPage<Income>(
      title: "${widget.income.pk == null ? "Create" : "Edit"}  Income",
      keyFieldChangedHandler: widget.generateProjections.generateProjections,
      item: widget.income,
      createNew: widget.createNew,
      updateItem: widget.updateItem,
      deleteItem: widget.deleteItem,
      formToItem: formToIncome,
      generateUniqueInputs: generateUniqueInputs,
    );
  }
}