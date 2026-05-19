// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';

class CrudListPage<T extends DomainModel> extends StatefulWidget {
  final Future<T>       Function(T empty)? createNew;  // C
  final Future<List<T>> Function()         getAll;     // R - mandatory
  final Future<T>       Function(T)?       updateItem; // U
  final Future<void>    Function(T)?       deleteItem; // D
  
  /*
    Optional method for creating a new entity.
    Optional edit page.
  */
  final T      Function()?       createEmpty;
  final Widget Function(T item)? editPage;

  /*
    This allows building a custom display widget.
  */
  final Widget Function(T) buildTileWidget;

  /*
    This will link models together to get extended information for display.
  */
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
    loadItems(); // asynchronous call to load entities
  }

  /*
    When call is busy, show loading.
  */
  Future<void> loadItems() async {
    setState(() => loading = true);

    var all = await widget.getAll(); 
    if (widget.joinExtraModels != null){
      all = await widget.joinExtraModels!(all);
    }
    setState((){
      items = all;
      loading = false;
    });
  }

  /*
    Clicking an existing Entity will open an edit page for it.
    Creating a new entity will do the same, but with template info.
    Returning from that edit page is also handled here.
  */
  Future<void> openEditPageAndHandleChanges(T item, BuildContext context) async {
    /* 
      Expect the edit page to only return something if it was a valid change.
      This way we don't ha
    */
    await Navigator.push<T?>(context,
      MaterialPageRoute(builder: (_) => widget.editPage!(item)),
    );

    // Finally, reload the items from the DB
    await loadItems();
  }

  @override
  Widget build(BuildContext context) {
    /*
      AppBar might eventually display important info
    */
    final appBar = AppBar();

    /* 
      Loading body and page body
    */
    final loadingBody = const Center(child: CircularProgressIndicator());
    /*
      Page body is ListView.builder
    */
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
          openEditPageAndHandleChanges(widget.createEmpty!(), context);
        },
        child: const Icon(Icons.add),
      );

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(index: loading ? 0 : 1, children: [ loadingBody, pageBody ]),
      floatingActionButton: addButton,
    );
  }
}