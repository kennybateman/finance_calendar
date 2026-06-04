// Dart and Flutter
import 'package:finance_calendar/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';
import 'package:finance_calendar/domain/models/settings.dart';

class CrudListPage<T extends DomainModel<T>> extends StatefulWidget {
  final Future<void> Function()? preloadHook;
  final Future<void> Function()? preloadHookFailHandler;

  final Future<List<T>> Function() getAll;
  final Widget Function(T, double) buildTileWidget;
  
  final bool useAddButton;
  final T Function()? createNewTemp;
  final Widget Function(T item)? editPage;
  final Widget Function(T item)? detailPage;

  final SettingsRepository settingsRepo;

  final Future<void> Function()? scrollToBottomHandler;
  final Future<List<T>> Function(int)? getMoreAfter;

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
    required this.settingsRepo,
    this.scrollToBottomHandler,
    this.getMoreAfter,
  });

  @override
  State<CrudListPage<T>> createState() => CrudListPageState<T>();
}

class CrudListPageState<T extends DomainModel<T>> extends State<CrudListPage<T>> {
  late bool loading = true;
  late bool loadingMore = false;
  late String statusMessage = "";
  late List<T> items = [];
  
  /* zoom variables */
  late double startScale = widget.settingsRepo.getSettings().fontSize;
  late double scale = startScale;

  final ScrollController scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    scrollController.addListener(onScroll);
    loadItems(); // async call
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void onScroll() async {
    /* only on scroll event rn is a bottom handler */
    if (widget.scrollToBottomHandler != null){
      final current = scrollController.position.pixels;
      final bottom = scrollController.position.maxScrollExtent;
      if (current >= bottom - 200 && !loading){
        await bottomHandlerAndLoadMore();
      }
    }
  }

  Future<void> bottomHandlerAndLoadMore() async {
    setState((){
      loadingMore = true;
    });

    try {
      /* this will generate more items, but not return them */
      await widget.scrollToBottomHandler!();   
    } 
    on Exception catch(exception){
      setState((){
        statusMessage = exception.toString();
      });      
    }

    final lastItem = items.last;
    List<T> allAfterLast = await widget.getMoreAfter!(lastItem.pk!); 

    setState((){
      items.addAll(allAfterLast);
      loadingMore = false;
    });   
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
    final getMoreEnabled = widget.getMoreAfter != null;

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
          onPressed: () async {
            var settings = widget.settingsRepo.getSettings();
            setState(() {
              scale = (settings.fontSize - 0.1).clamp(0.4, 1.0);
            });
            widget.settingsRepo.updateSettings(Settings(darkMode: settings.darkMode, fontSize: scale));
          },
        ),
        IconButton(
          icon: Icon(Icons.add),
          tooltip: "Zoom in",
          onPressed: () {
            var settings = widget.settingsRepo.getSettings();
            setState(() {
              scale = (settings.fontSize + 0.1).clamp(0.4, 1.0);
            });
            widget.settingsRepo.updateSettings(Settings(darkMode: settings.darkMode, fontSize: scale));
          },
        ),
      ]
    );

    final circleWaiting = const Center(child: CircularProgressIndicator());

    final pageBody = ListView.builder(
        controller: scrollController,
        itemCount: items.length + (getMoreEnabled ? 1 : 0),
        itemBuilder: (context, index) {
          /* if last item, then show circular progress thingy */
          if (index == items.length && getMoreEnabled) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          /* otherwise make item */
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