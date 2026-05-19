// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';

class ReadListPage<T extends DomainModel> extends StatefulWidget {
  final Future<Iterable<T>> Function() getAll;
  final Widget Function(T item)? detailPage;

  final Widget Function(T) buildTileWidget;

  final Future<void> Function()? preloadHook;

  const ReadListPage({
    super.key,
    required this.getAll,
    this.detailPage,
    required this.buildTileWidget,
    this.preloadHook,
  });

  @override
  State<ReadListPage<T>> createState() => ReadListPageState<T>();
}

class ReadListPageState<T extends DomainModel> extends State<ReadListPage<T>> {
  List<T> items = [];
  bool loading = true;
  String status = "";

  @override
  void initState(){
    super.initState();

    loadItems();
  }

  Future<void> loadItems() async {
    setState(() => loading = true);

    /* preload hook might be complex, so expect returning exceptions */
    // if (widget.preloadHook != null){
    //   try{ await widget.preloadHook!(); }
    //   on Exception catch(exception){
    //     setState((){
    //       status = exception.toString();
    //     });
    //   }
    // }

    final all = await widget.getAll(); 
    
    if (!mounted) return;
    setState((){
      items = all.toList();
      loading = false;
    });
  }

  Future<void> openDetailPageAndHandleChanges(T item, BuildContext context) async {
    await Navigator.push<T?>(context,
      MaterialPageRoute(builder: (_) => widget.detailPage!(item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(title: Text(status));
    var loadingBody = const Center(child: CircularProgressIndicator());

    var pageBody = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(title: widget.buildTileWidget(item), 
          onTap: () async { openDetailPageAndHandleChanges(item, context); });
        },
      );

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(index: loading ? 0 : 1, children: [ loadingBody, pageBody ]),
      floatingActionButton: null,
    );
  }
}