// Dart and Flutter
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
// DOMAIN
import '../../domain/models/income.dart';
import '../../domain/use_cases/helpers.dart';
import '../../domain/use_cases/edit_exception.dart';
import '../../domain/use_cases/generate_projections.dart';
// UI
import '../shared/date_form_input.dart';
import '../shared/select_form_input.dart';
import '../shared/text_form_input.dart';
import '../shared/crud_edit_page.dart';

//import 'dart:developer' as developer;

class EditIncomePage extends StatefulWidget{
  final GenerateProjectionsUseCase generateProjections;
  final Future<List<({int pk, String name})>> Function() getAccountNames;
  final Future<List<({int pk, String name})>> Function() getIncomeNames;
  final Future<Income>        Function(Income) createNew;  // C
  final Income income;                                     // R
  final Future<Income>        Function(Income) updateItem; // U
  final Future<void>          Function(Income) deleteItem; // D
  const EditIncomePage({super.key, 
    required this.generateProjections,
    required this.income,
    required this.getAccountNames,
    required this.getIncomeNames,
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

  late List<({int? pk, String name})> accountNames = [ ];
  late List<({int pk, String name})> incomeNames = [ ];

  static const String deselectAccountString = '';

  @override
  void initState() {
    super.initState();
    incomeToForm(widget.income);
    getAllAccounts(); // asynchronous call
    getAllIncome(); // asynchronous call
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void incomeToForm(Income income){
    nameController = TextEditingController(text: income.name);
    amountController = TextEditingController(text: currencyCentsToDollarsString(income.amount));
    dueFrequency = income.dueFrequency;
    payToAccountPk = income.payToAccountPk;
    dueDate = income.dueDate;
  }

  void getAllAccounts() async {
    final List<({int? pk, String name})> pkNameTuples = await widget.getAccountNames();
    /* add a null account for deselecting */
    final List<({int? pk, String name})> newAccountNames = [ ( pk: null as int?, name: deselectAccountString) ] + pkNameTuples;

    if (!mounted) return;
    setState((){
      accountNames = newAccountNames;
    });
  }

  void getAllIncome() async {
    final pkNameTuples = await widget.getIncomeNames();

    if (!mounted) return;
    setState((){
      incomeNames = pkNameTuples;
    });
  }

  void validateInput() {
    final newName = nameController.text;
    
    if (newName == "") {
      throw EditException("Name cannot be empty.");
    }

    /* Database doesn't allow same names. Don't rely on that though. Catch it here */
    for(var pkNameTuple in incomeNames){
      if (pkNameTuple.pk == widget.income.pk) continue;
      
      if (newName == pkNameTuple.name){
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
      dueDateAnchorDay: dueDate?.day,
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
      newPk = accountNames.firstWhere((a) => a.name == selectedAccountName).pk;
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

  Widget buildItemForm(){
    return Column(children: [
      TextFormInput("Name", nameController),
      TextFormInput("Amount", amountController),
      DateFormInput("Due date", dueDate, onDueDateChange),
      SelectFormInput("Frequency", ['monthly', 'bimonthly', 'weekly', 'biweekly'], dueFrequency, dueFrequencyChanged),
      SelectFormInput("Pay to", 
        accountNames.map((a)=>a.name).toList(), 
        accountNames.firstWhereOrNull((an) => an.pk == payToAccountPk)?.name, 
        payToAccountChanged),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return CrudEditPage<Income>(
      title: "${widget.income.pk == null ? "Create" : "Edit"}  Income",
      keyFieldChangedHandler: widget.generateProjections.generateProjections,
      keyFieldChangedFailureHandler: widget.generateProjections.clearProjections,
      item: widget.income,
      createItem: widget.createNew,
      updateItem: widget.updateItem,
      deleteItem: widget.deleteItem,
      formToItem: formToIncome,
      buildItemForm: buildItemForm,
    );
  }
}