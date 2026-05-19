// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import '../../domain/models/bill.dart';
import '../../domain/use_cases/helpers.dart';
import '../../domain/use_cases/edit_exception.dart';
import '../../domain/use_cases/generate_projections.dart';
import '../../domain/models/account.dart';
// UI
import '../shared/date_form_input.dart';
import '../shared/select_form_input.dart';
import '../shared/text_form_input.dart';

class EditBillPage extends StatefulWidget{
  final GenerateProjectionsUseCase generateProjections;
  final Future<List<Account>> Function() getAllAccounts;
  final Future<List<Bill>> Function() getAllBills;
  final Future<Bill>          Function(Bill) createNew;  // C
  final Bill bill;                                       // R (bill being edited)
  final Future<Bill>          Function(Bill) updateItem; // U
  final Future<void>          Function(Bill) deleteItem; // D
  const EditBillPage({super.key,
    required this.generateProjections,
    required this.bill,
    required this.getAllAccounts,
    required this.getAllBills,
    required this.createNew,
    required this.updateItem,
    required this.deleteItem,
  });

  @override
  State<EditBillPage> createState() => EditBillPageState();
}

class EditBillPageState extends State<EditBillPage> {
  late bool loading;
  late GenerateProjectionsUseCase generateProjections;
  late TextEditingController nameController;
  late TextEditingController amountController;
  late DateTime? dueDate;
  late String dueFrequency;
  late int? payFromAccountPk;
  /* need access to all accounts ot allow changing pay from account */
  late List<Account> allAccounts;
  late List<String> accountNames = ['loading']; // display account names for the selection
  late Map<int?, Account?> accountsByPk = { null: null };
  /* need access to all bill names to prevent saving duplicate names */
  late List<Bill> allBills;

  late String errorMessage;

  static const String deselectAccountString = '';

  @override
  void initState() {
    super.initState();
    billToForms(widget.bill);
    getAllAccountInfo(); // asynchronous call
    getAllBills();
    errorMessage = "";
    loading = false;
  }


  void billToForms(Bill bill){
    nameController = TextEditingController(text: bill.name);
    amountController = TextEditingController(text: currencyCentsToDollarsString(bill.amount));
    dueFrequency = bill.dueFrequency;
    payFromAccountPk = bill.payFromAccountPk;
    dueDate = bill.dueDate;
  }


  void getAllBills() async {
    final bills = await widget.getAllBills();
    setState((){
      allBills = bills;
    });
  }

  void getAllAccountInfo() async {
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

  void validateInput() {
    /* Database doesn't allow same names. Don't rely on that though. Catch it here */
    final newName = nameController.text;
    for(var bill in allBills){
      /* allBills all have pks, widget.bill might not, either way, we are allowed to change the name */
      if (bill.pk == widget.bill.pk) continue;
      if (newName == bill.name){
        throw EditException("Existing Bill already uses this name");
      }
    }
  }

  Bill formToBill() {
    
    validateInput();

    return Bill(
      pk: widget.bill.pk,
      name: nameController.text,
      amount: dollarsStringToCurrencyCents(amountController.text),
      dueFrequency: dueFrequency,
      payFromAccountPk: payFromAccountPk,
      dueDate: dueDate,
    );
  }

  void update() async {
    try {

      final updated = formToBill();
      if (updated != widget.bill){
        final _ = await widget.updateItem(updated);
      }

      if (widget.bill.keyFieldsChanged(updated)){
        /* run the generator */
        setState((){
          loading = true;
        });
        await widget.generateProjections.generateProjections();
      }

      if (!mounted) return;
      Navigator.pop(context);

    } on EditException catch(e){

      setState((){
        errorMessage = e.toString();
      });

    } on GenerateProjectionsException catch(_){
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void remove() async {
    try {
      await widget.deleteItem(widget.bill);
      if (!mounted) return;
      Navigator.pop(context);
    } 
    finally{

    }
  }

  void create() async {
    try {

      final created = formToBill();
      final _ = await widget.createNew(created);

      /* run the generator */
      setState((){
        loading = true;
      });
      
      await widget.generateProjections.generateProjections();

      if (!mounted) return;
      Navigator.pop(context);

    } on EditException catch(e){

      setState((){
        errorMessage = e.toString();
      });

    } on GenerateProjectionsException catch(_){
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void onDueDateChange(DateTime date){
    setState((){
      dueDate = date;
    });
  }

  void payFromAccountChanged(String selectedAccountName){
    int? newPk;

    if (selectedAccountName == deselectAccountString){
      newPk = null;
    }
    else{
      newPk = allAccounts.firstWhere((a) => a.name == selectedAccountName).pk;
    }

    setState((){
      payFromAccountPk = newPk;
    });
  }

  void dueFrequencyChanged(String value){
    setState(() {
      dueFrequency = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> inputs = [
      TextFormInput("Name", nameController),
      TextFormInput("Amount", amountController),
      DateFormInput("Due date", dueDate, onDueDateChange),
      SelectFormInput("Frequency", ['monthly', 'bimonthly', 'weekly', 'biweekly'], dueFrequency, dueFrequencyChanged),
      SelectFormInput("Pay from", accountNames, accountsByPk[payFromAccountPk]?.name, payFromAccountChanged),
    ];

    if (widget.bill.pk == null) {
      inputs += [
        SizedBox(height: 24),
        ElevatedButton(onPressed: create, child: Text("Create")),
      ];
    }
    else{
      inputs += [
        SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          ElevatedButton(onPressed: update, child: Text("Update")),
          ElevatedButton(onPressed: remove, child: Text("Remove")),
        ])
      ];
    }

    inputs.add(Text(errorMessage, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));

    final loadingBody = const Center(child: CircularProgressIndicator());
    final body = Padding(padding: EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: inputs));

    return Scaffold(
      appBar: AppBar(title: Text("Edit Bill")),
      body: IndexedStack(index: loading ? 0 : 1, children: [ loadingBody, body ]),
    );
  }
}