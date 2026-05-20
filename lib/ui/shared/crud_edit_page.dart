// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';
import 'package:finance_calendar/domain/use_cases/edit_exception.dart';
// UI
// import '../shared/date_form_input.dart';
// import '../shared/select_form_input.dart';
// import '../shared/text_form_input.dart';

class CrudEditPage<T extends DomainModel<T>> extends StatefulWidget{
  final Future<void> Function() generateProjections;

  final Future<List<DomainModel>> Function() getSupportingModels;
  final Future<T>       Function(T) createNew;  // C
  final T item;                                 // R (account being edited)
  final Future<T>       Function(T) updateItem; // U
  final Future<void>    Function(T) deleteItem; // D

  final void Function(T) itemToForms;
  final T Function() formToItem;

  final void Function() validateInput;

  final List<Widget> inputs;

  const CrudEditPage({
    super.key,
    required this.generateProjections,
    required this.item,
    required this.getSupportingModels,
    required this.createNew,
    required this.updateItem,
    required this.deleteItem,
    required this.itemToForms,
    required this.formToItem,
    required this.validateInput,
    required this.inputs,
  });

  @override
  State<CrudEditPage<T>> createState() => CrudEditPageState<T>();
}

class CrudEditPageState<T extends DomainModel<T>> extends State<CrudEditPage<T>> {
  late bool loading;
  late String errorMessage;
  late List<Widget> inputs;

  @override
  void initState() {
    super.initState();
    widget.itemToForms(widget.item);
    widget.getSupportingModels();
    errorMessage = '';
    loading = false;
    inputs = widget.inputs;
  }

  void update() async {
    try {

      final updated = widget.formToItem();
      if (updated != widget.item){
        final _ = await widget.updateItem(updated);
      }

      if (widget.item.keyFieldsChanged(updated)){
        setState((){
          loading = true;
        });
        await widget.generateProjections();
      }

      if (!mounted) return;
      Navigator.pop(context);

    } on EditException catch(e){

      setState((){
        errorMessage = e.toString();
      });

    } on Exception catch(_){
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void remove() async {
    try {
      await widget.deleteItem(widget.item);
      if (!mounted) return;
      Navigator.pop(context);
    } 
    finally{

    }
  }

  void create() async {

  }

  @override
  Widget build(BuildContext context) {

    if (widget.item.pk == null) {
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
        ]),
      ];
    }

    inputs.add(Text(errorMessage, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));

    final loadingBody = const Center(child: CircularProgressIndicator());
    var body = Padding(padding: EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: inputs));

    return Scaffold(
      appBar: AppBar(title: Text("Edit Account")),
      body: IndexedStack(index: loading ? 0 : 1, children: [ loadingBody, body ]),
    );
  }
}