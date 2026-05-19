// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../data/services/database_wrapper.dart';
// UI
import 'finance_calendar_view_model.dart';

class FinanceCalendar extends StatefulWidget {
  final DatabaseWrapper databaseWrapper;
  final FinanceCalendarViewModel viewModel;
  FinanceCalendar({ 
    super.key, 
    required this.databaseWrapper 
  }) : 
    viewModel = FinanceCalendarViewModel(databaseWrapper);

  @override
  State<FinanceCalendar> createState() => FinanceCalendarState();
}

class FinanceCalendarState extends State<FinanceCalendar>{
  late bool dbIsInitialized;

  @override
  void initState() {
    super.initState();

    dbIsInitialized = false;
    initDB();
  }

  Future<void> initDB() async {
    await widget.databaseWrapper.init();

    setState((){
      dbIsInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final circleWaiting = const Center(child: CircularProgressIndicator());
            
    return MaterialApp(
      title: widget.viewModel.appTitle, 
      theme: widget.viewModel.themeData, 
      home: Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: dbIsInitialized ? widget.viewModel.homeBody : circleWaiting,
      ),
    );
  }
}
