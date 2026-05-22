// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import '../../domain/models/account.dart';
import '../../domain/use_cases/helpers.dart';
import '../../domain/use_cases/edit_exception.dart';
import '../../domain/use_cases/generate_projections.dart';
// UI
import '../shared/date_form_input.dart';
import '../shared/select_form_input.dart';
import '../shared/text_form_input.dart';
import '../shared/crud_edit_page.dart';

class EditAccountPage extends StatefulWidget{
  final GenerateProjectionsUseCase generateProjections;
  final Future<List<Account>> Function() getAll;
  final Future<Account>       Function(Account) createNew;  // C
  final Account account;                                    // R (account being edited)
  final Future<Account>       Function(Account) updateItem; // U
  final Future<void>          Function(Account) deleteItem; // D
  const EditAccountPage({super.key,
    required this.generateProjections,
    required this.account,
    required this.getAll,
    required this.createNew,
    required this.updateItem,
    required this.deleteItem,
  });

  @override
  State<EditAccountPage> createState() => EditAccountPageState();
}

class EditAccountPageState extends State<EditAccountPage> {
  late TextEditingController nameController;            // name (TEXT CONTROLLER)
  late TextEditingController balanceController;         // balance (TEXT CONTROLLER)
  late DateTime? balanceDate;                           // balance date
  late String accountType;                              // account type
  late TextEditingController creditLimitController;     // credit limit (TEXT CONTROLLER)
  late TextEditingController creditInterestController;  // credit interest (TEXT CONTROLLER)
  late DateTime? creditInterestDueDate;                 // credit interest due date
  late String creditInterestDueFrequency;               // credit interest due frequency
  late int? creditInterestPayFromAccountPk;             // credit interest pay from account
  late bool payFromThisAccount;
  /* need access to all accounts to allow changing pay from account */
  late List<Account> allAccounts;
  late List<String> accountNames = ['loading']; // display account names for the selection
  late Map<int?, Account?> accountsByPk = { null: null };

  /* perfect example of something to go into a view model */
  static const String deselectAccountString = '';
  static const String payFromThisAccountString = 'Pay from this account';

  @override
  void initState() {
    super.initState();
    accountToForms(widget.account);
    getAllAccounts();
  }

  void accountToForms(Account account){
    nameController = TextEditingController(text: account.name);
    balanceController = TextEditingController(text: currencyCentsToDollarsString(account.balance));
    balanceDate = account.balanceDate;
    accountType = account.accountType;
    creditLimitController = TextEditingController(text: currencyCentsToDollarsString(account.creditLimit));
    creditInterestController = TextEditingController(text: currencyCentsToDollarsString(account.interest));
    creditInterestDueFrequency = account.dueFrequency;
    creditInterestDueDate = account.dueDate;
    creditInterestPayFromAccountPk = account.payFromAccountPk;
    payFromThisAccount = account.payFromThisAccount;
  }

  void getAllAccounts() async {
    final editing = widget.account.pk != null;
    final accounts = await widget.getAll();

    /* 
      If this is the first account (credit), we want to allow the user to set it as the pay from account.
      This is hard, because at the time of creation, there are no account names to serve.
      Even on subsequent account creations it's not possible to serve the currently created account in the account names list. (thus can't base this on length == 0).
      Always add an option to Account.payFromAccount for 'Pay from this credit account'.
      Also add blank, allowing deseleting accounts.
    */
    var newAccountNames = [ deselectAccountString, payFromThisAccountString ] + accounts.map((a) => a.name).toList();
    /* if editing existing account, remove that account name, 'Pay from this credit account' will be used instead. */
    if (editing){
      newAccountNames.remove(widget.account.name);
    }
    
    /* set this up too */
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

  void validateInput(){
    /* Database doesn't allow same names. Don't rely on that though. Catch it here */
    final newName = nameController.text;
    for(var account in allAccounts){
      /* allAccounts all have pks, widget.account might not, either way, we are allowed to change the name */
      if (account.pk == widget.account.pk) continue;
      if (newName == account.name){
        throw EditException("Existing account already uses this name");
      }
    }
  }

  Account formToAccount(){
    validateInput();
    return Account(
      pk: widget.account.pk,
      name: nameController.text,
      balance: dollarsStringToCurrencyCents(balanceController.text),
      balanceDate: balanceDate,
      accountType: accountType,
      creditLimit: dollarsStringToCurrencyCents(creditLimitController.text),
      interest: dollarsStringToCurrencyCents(creditInterestController.text),
      dueFrequency: creditInterestDueFrequency,
      dueDate: creditInterestDueDate,
      payFromAccountPk: creditInterestPayFromAccountPk,
    );
  }

  void onDueDateChange(DateTime date){
    setState((){
      creditInterestDueDate = date;
    });
  }

  void onBalanceDateChange(DateTime date){
    setState((){
      balanceDate = date;
    });
  }

  void accountTypeChanged(String value){
    setState(() {
      accountType = value;
    });
  }

  void payFromAccountChanged(String selectedAccountName){
    int? newPk;
    bool newPayFromThisAccount;

    if (selectedAccountName == deselectAccountString){
      newPk = null;
      newPayFromThisAccount = false;
    }
    else if (selectedAccountName == payFromThisAccountString){
      newPk = widget.account.pk;
      newPayFromThisAccount = true;
    }
    else{
      newPk = allAccounts.firstWhere((a) => a.name == selectedAccountName).pk;
      newPayFromThisAccount = false;
    }

    setState((){
      creditInterestPayFromAccountPk = newPk;
      payFromThisAccount = newPayFromThisAccount;
    });
  }

  void dueFrequencyChanged(String value){
    setState(() {
      creditInterestDueFrequency = value;
    });
  }

  String? getDefaultPayFromSelection(){
    if (creditInterestPayFromAccountPk == widget.account.pk){
      return payFromThisAccountString;
    }
    return accountsByPk[creditInterestPayFromAccountPk]?.name;
  }

  List<Widget> generateUniqueInputs(){
      List<Widget> inputs = [
      TextFormInput("Name", nameController),
      TextFormInput("Balance", balanceController),
      DateFormInput("Balance date", balanceDate, onBalanceDateChange),
      SelectFormInput("Account type", ['debit', 'credit'], accountType, accountTypeChanged),
    ];

    if (accountType == 'credit'){
      inputs += [
        TextFormInput("Credit limit", creditLimitController),
        TextFormInput("Interest rate (%/yr)", creditInterestController),
        SelectFormInput("Interest Due Frequency", ['monthly', 'bimonthly', 'weekly', 'biweekly'], creditInterestDueFrequency, dueFrequencyChanged),
        DateFormInput("Interest Due date", creditInterestDueDate, onDueDateChange),
        SelectFormInput("Pay from", accountNames, getDefaultPayFromSelection(), payFromAccountChanged),
      ];
    }  
    return inputs;
  }

  @override
  Widget build(BuildContext context) {
    return CrudEditPage<Account>(
      title: "${widget.account.pk == null ? "Create" : "Edit"} Account",
      keyFieldChangedHandler: widget.generateProjections.generateProjections,
      item: widget.account,
      createNew: widget.createNew,
      updateItem: widget.updateItem,
      deleteItem: widget.deleteItem,
      formToItem: formToAccount,
      generateUniqueInputs: generateUniqueInputs,
    );
  }
}