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
  final String title;
  final Future<T>       Function(T) createNew;  // C
  final T item;                                 // R (account being edited)
  final Future<T>       Function(T) updateItem; // U
  final Future<void>    Function(T) deleteItem; // D

  final T Function() formToItem;

  final Future<void> Function() keyFieldChangedHandler;

  final List<Widget> Function() generateUniqueInputs;

  const CrudEditPage({
    super.key,
    this.title="",
    required this.keyFieldChangedHandler,
    required this.item,
    required this.createNew,
    required this.updateItem,
    required this.deleteItem,
    required this.formToItem,
    required this.generateUniqueInputs,
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
    errorMessage = '';
    loading = false;
  }

  List<Widget> generateCommonWidgets(){
    List<Widget> crudWidgets = [];
    if (widget.item.pk == null) {
      crudWidgets += [
        SizedBox(height: 24),
        ElevatedButton(onPressed: create, child: Text("Create")),
      ];
    }
    else{
      crudWidgets += [
        SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          ElevatedButton(onPressed: update, child: Text("Update")),
          ElevatedButton(onPressed: remove, child: Text("Remove")),
        ]),
      ];
    }
    /* error widget at the bottom */
    crudWidgets.add(Text(errorMessage, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
    return crudWidgets;
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

        await widget.keyFieldChangedHandler();
      }

      if (!mounted) return;
      Navigator.pop(context);

    } on EditException catch(e){

      setState((){
        errorMessage = e.toString();
      });

    } on Exception catch(e){
      if (!mounted) return;

      setState((){
        errorMessage = e.toString();
      });  

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
    try {

      final created = widget.formToItem();
      final _ = await widget.createNew(created);

      /* run the generator */
      setState((){
        loading = true;
      });

      await widget.keyFieldChangedHandler();
        
      if (!mounted) return;
      Navigator.pop(context);

    } on EditException catch(e){

      setState((){
        errorMessage = e.toString();
      });
      
    } on Exception catch(e){
      if (!mounted) return;

      setState((){
        errorMessage = e.toString();
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    var inputs = widget.generateUniqueInputs() + generateCommonWidgets();

    final loadingBody = const Center(child: CircularProgressIndicator());
    /* why is this so complicated looking? I didn't add zooming here... */
    var body = Padding(
      padding: EdgeInsets.all(16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: inputs
      )
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: IndexedStack(index: loading ? 0 : 1, children: [ loadingBody, body ]),
    );
  }
}