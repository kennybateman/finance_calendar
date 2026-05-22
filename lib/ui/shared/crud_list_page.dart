// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';

class CrudListPage<T extends DomainModel<T>> extends StatefulWidget {
  final Future<void> Function()? preloadHook;
  final Future<void> Function()? preloadHookFailHandler;

  final Future<List<T>> Function() getAll;
  final Widget Function(T, double) buildTileWidget;
  
  final bool useAddButton;
  final T Function()? createNewTemp;
  final Widget Function(T item)? editPage;
  final Widget Function(T item)? detailPage;

  const CrudListPage({
    super.key,
    this.preloadHook,
    this.preloadHookFailHandler,

    required this.getAll,
    required this.buildTileWidget,

    required this.useAddButton,
    this.createNewTemp,
    this.editPage,
    this.detailPage,
  });

  @override
  State<CrudListPage<T>> createState() => CrudListPageState<T>();
}

class CrudListPageState<T extends DomainModel<T>> extends State<CrudListPage<T>> {
  late bool loading = true;
  late String statusMessage = "";
  late List<T> items = [];
  
  /* zoom variables */
  late double startScale = 1.0;
  late double scale = 1.0;

  @override
  void initState(){
    super.initState();
    loading = true;
    statusMessage = "";

    /* zoom variables */
    startScale = 1.0;
    scale = startScale;
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
          statusMessage = exception.toString();
        });
      }
    }

    var all = await widget.getAll(); 

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

    /* should probably do the preload hook again here */
    await loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final error = statusMessage != "";

    final appBar = AppBar(
      title: Text(statusMessage, 
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
          final empty = widget.createNewTemp!();
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