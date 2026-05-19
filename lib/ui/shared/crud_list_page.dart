// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';

class CrudListPage<T extends DomainModel> extends StatefulWidget {
  final Future<T>       Function(T empty)? createNew;  // C
  final Future<List<T>> Function()         getAll;     // R - mandatory
  final Future<T>       Function(T)?       updateItem; // U
  final Future<void>    Function(T)?       deleteItem; // D
  
  final T      Function()?       createEmpty;
  final Widget Function(T item)? editPage;

  final Widget Function(T) buildTileWidget;

  final Future<List<T>> Function(List<T>)? joinExtraModels;

  const CrudListPage({
    super.key,
    required this.buildTileWidget,
    required this.getAll,
    this.createNew,
    this.updateItem,
    this.deleteItem,
    this.joinExtraModels,
    this.createEmpty,
    this.editPage,
  });

  @override
  State<CrudListPage<T>> createState() => CrudListPageState<T>();
}

class CrudListPageState<T extends DomainModel> extends State<CrudListPage<T>> {
  List<T> items = [];
  bool loading = true;

  @override
  void initState(){
    super.initState();
    loadItems(); // async call
  }

  Future<void> loadItems() async {
    setState((){ 
      loading = true;
    });

    var all = await widget.getAll(); 

    if (widget.joinExtraModels != null){
      all = await widget.joinExtraModels!(all);
    }

    setState((){
      items = all;
      loading = false;
    });
  }

  Future<void> openEditPageAndHandleChanges(T item, BuildContext context) async {
    await Navigator.push<T?>(context,
      MaterialPageRoute(builder: (_) => widget.editPage!(item)),
    );

    await loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar();
    final circleWaiting = const Center(child: CircularProgressIndicator());

    final pageBody = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: widget.buildTileWidget(item), 
            onTap: () async { openEditPageAndHandleChanges(item, context); 
          });
        },
      );

    final addButton = FloatingActionButton(
        heroTag: null, // this fixes some crazy bug that exceptions when opening the page. No clue why either. 
        onPressed: () async { 
          final empty = widget.createEmpty!();
          openEditPageAndHandleChanges(empty, context);
        },
        child: const Icon(Icons.add),
      );

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(index: loading ? 0 : 1, children: [ circleWaiting, pageBody ]),
      floatingActionButton: addButton,
    );
  }
}