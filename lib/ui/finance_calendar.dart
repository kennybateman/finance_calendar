// Dart and Flutter
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
// DATA
import '../data/services/database_wrapper.dart';
import '../data/services/settings_wrapper.dart';
// UI
import 'finance_calendar_view_model.dart';

//import 'dart:developer' as dev;

class FinanceCalendar extends StatefulWidget {
  final DatabaseWrapper databaseWrapper;
  final SettingsWrapper settingsWrapper;
  final Future<void> Function(Excel, String) saveHandler;
  final Future<void> Function(BuildContext) feedbackHandler;
  final FinanceCalendarViewModel viewModel;
  FinanceCalendar({ 
    super.key, 
    required this.databaseWrapper,
    required this.settingsWrapper,
    required this.saveHandler,
    required this.feedbackHandler,
  }) : 
    viewModel = FinanceCalendarViewModel(
      databaseWrapper, 
      settingsWrapper, 
      saveHandler: saveHandler,
      feedbackHandler: feedbackHandler,
    );

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

  /* this is just a callback to force rebuilding at this level */
  void updatedSettings(){
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    final bool darkMode = widget.settingsWrapper.getDarkMode();

    return MaterialApp(
      title: widget.viewModel.appTitle, 
      theme: ThemeData.light(), 
      darkTheme: ThemeData.dark(),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: dbIsInitialized ? widget.viewModel.generateHomeBody(updatedSettings) : widget.viewModel.loading,
      ),
    );
  }
}
