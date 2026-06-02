// Dart and Flutter
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
import 'package:flutter/material.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';
import 'package:finance_calendar/domain/use_cases/edit_exception.dart';
// UI

class CrudEditPage<T extends DomainModel<T>> extends StatefulWidget{
  final String title;

  final Future<T>       Function(T) createItem; // C
  final T item;                                 // R
  final Future<T>       Function(T) updateItem; // U
  final Future<void>    Function(T) deleteItem; // D

  final Widget Function() buildItemForm;
  final T Function() formToItem;

  final Future<void> Function() keyFieldChangedHandler;

  const CrudEditPage({
    super.key,
    this.title="",
    required this.createItem, // C
    required this.item,       // R
    required this.updateItem, // U
    required this.deleteItem, // D
    required this.buildItemForm,
    required this.formToItem,
    required this.keyFieldChangedHandler,
  });

  @override
  State<CrudEditPage<T>> createState() => CrudEditPageState<T>();
}

class CrudEditPageState<T extends DomainModel<T>> extends State<CrudEditPage<T>> {
  bool loading = false;
  String errorMessage = '';

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
          ElevatedButton(onPressed: delete, child: Text("Delete")),
        ]),
      ];
    }
    /* error widget at the bottom */
    crudWidgets.add(Text(errorMessage, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
    return crudWidgets;
  }

  void create() async {
    executeCrud(() async {
      final created = widget.formToItem();
      final _ = await widget.createItem(created);
    });
  }

  void update() async {
    executeCrud(() async {
      final updated = widget.formToItem();
      if (updated != widget.item){
        final _ = await widget.updateItem(updated);
      }
    });
  }

  void delete() async {
    executeCrud(() async {
      await widget.deleteItem(widget.item);
    });
  }

  Future<void> executeCrud(Future<void> Function() action) async {
    try {
      await action();
    }
    on EditException catch(e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    }
    on Exception catch(e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });   
    }

    /* once validation and db operation has passed, we can run projections. If they fail who cares. */    
    if (!mounted) return;
    try {
      setState((){ loading = true; });
      await widget.keyFieldChangedHandler();
    }
    on GenerateProjectionsException catch(_){
      /* nothing to do with exception, just ignore it */
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loadingBody = const Center(child: CircularProgressIndicator());
    var body = Padding(
      padding: EdgeInsets.all(16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.buildItemForm(),
          ...generateCommonWidgets(),
        ]
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: IndexedStack(index: loading ? 0 : 1, children: [ loadingBody, body ]),
    );
  }
}