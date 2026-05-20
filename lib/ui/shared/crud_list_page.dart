// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';

class CrudListPage<T extends DomainModel<T>> extends StatefulWidget {
  final Future<void> Function()? preloadHook;
  final Future<void> Function()? preloadHookFailHandler;

  final Future<T>       Function(T empty)? createNew;  // C
  final Future<List<T>> Function()         getAll;     // R - mandatory
  final Future<T>       Function(T)?       updateItem; // U
  final Future<void>    Function(T)?       deleteItem; // D
  
  final T      Function()?       createEmpty;
  final Widget Function(T item)? editPage;
  final Widget Function(T item)? detailPage;

  final Widget Function(T, double) buildTileWidget;

  final Future<List<T>> Function(List<T>)? joinExtraModels;

  final bool useAddButton;

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
    this.detailPage,
    this.preloadHook,
    this.preloadHookFailHandler,
    this.useAddButton = false,
  });

  @override
  State<CrudListPage<T>> createState() => CrudListPageState<T>();
}

class CrudListPageState<T extends DomainModel<T>> extends State<CrudListPage<T>> {
  List<T> items = [];
  bool loading = true;
  String status = "";

  /* pinch zoom variables */
  double startScale = 1.0;
  double scale = 1.0;

  @override
  void initState(){
    super.initState();
    loadItems(); // async call
  }

  Future<void> loadItems() async {
    setState((){ 
      loading = true;
    });


    if (widget.preloadHook != null){
      try{ 
        await widget.preloadHook!(); 
      }
      on Exception catch(exception){

        if (widget.preloadHookFailHandler != null){
          widget.preloadHookFailHandler!();
        }
        
        setState((){
          status = exception.toString();
        });
      }
    }

    var all = await widget.getAll(); 

    /* this should totally be the job of the repo */
    if (widget.joinExtraModels != null){
      all = await widget.joinExtraModels!(all);
    }

    setState((){
      items = all;
      loading = false;
    });
  }

  Future<void> openEditPageAndHandleChanges(T item, BuildContext context) async {
    /* not that great atm. But basically, assume edit page, unless null, then default to detail page
    */
    final subPage = widget.editPage != null ? widget.editPage! : widget.detailPage!;

    await Navigator.push<T?>(context,
      MaterialPageRoute(builder: (_) => subPage(item)),
    );

    /* should probably to the preload hook again here */
    await loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final error = status != "";

    final appBar = AppBar(
      title: Text(status, 
      style: TextStyle(
        color: error ? Colors.red : Colors.black, 
        fontWeight: FontWeight.bold
      )),
      actions: [
        IconButton(
          icon: Icon(Icons.remove),
          tooltip: "Zoom out",
          onPressed: () {
            setState(() {
              scale = (scale - 0.1).clamp(0.4, 1.0);
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.add),
          tooltip: "Zoom in",
          onPressed: () {
            setState(() {
              scale = (scale + 0.1).clamp(0.4, 1.0);
            });
          },
        ),
      ]
    );

    final circleWaiting = const Center(child: CircularProgressIndicator());

    final pageBody = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: widget.buildTileWidget(item, scale), 
            dense: true,
            visualDensity: VisualDensity.comfortable,
            minTileHeight: 0,
            onTap: () async { 
              openEditPageAndHandleChanges(item, context); 
            }
          );
        },
      );

    final indexedStack = IndexedStack(index: loading ? 0 : 1, children: [ circleWaiting, pageBody ]);

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
      body: indexedStack,
      floatingActionButton: widget.useAddButton ? addButton : null, // not great but wutever for now
    );
  }
}