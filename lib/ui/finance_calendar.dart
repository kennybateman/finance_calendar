// Dart and Flutter
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
// DATA
import '../data/services/database_wrapper.dart';
import '../data/services/settings_wrapper.dart';
import '../data/repositories/projections_repository.dart';
import '../data/repositories/accounts_repository.dart';
import '../data/repositories/income_repository.dart';
import '../data/repositories/bills_repository.dart';
import '../data/repositories/settings_repository.dart';
// DOMAIN
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
// UI
import 'finance_calendar_view_model.dart';
import 'projections/projections_page.dart';
import 'calendar/calendar_page.dart';
import 'accounts/accounts_page.dart';
import 'income/income_page.dart';
import 'bills/bills_page.dart';
import 'settings/settings_page.dart';
import 'information/information_page.dart';

//import 'dart:developer' as dev;

class FinanceCalendar extends StatefulWidget {
  /* These are OS dependent methods that must be figured out at the main() level */
  final DatabaseWrapper databaseWrapper;
  final SettingsWrapper settingsWrapper;
  final Future<void> Function(Excel, String) saveHandler;
  final Future<void> Function(BuildContext) feedbackHandler;
  const FinanceCalendar({ 
    super.key, 
    required this.databaseWrapper,
    required this.settingsWrapper,
    required this.saveHandler,
    required this.feedbackHandler,
  });

  @override
  State<FinanceCalendar> createState() => FinanceCalendarState();
}

class FinanceCalendarState extends State<FinanceCalendar>{
  late final FinanceCalendarViewModel viewModel;

  @override
  void initState() {
    super.initState();

    initDB();

    viewModel = FinanceCalendarViewModel(
      saveHandler: widget.saveHandler,
      feedbackHandler: widget.feedbackHandler,
      billsRepo: BillsRepository(widget.databaseWrapper),  
      incomeRepo: IncomeRepository(widget.databaseWrapper),
      accountsRepo: AccountsRepository(widget.databaseWrapper),
      projectionsRepo: ProjectionsRepository(widget.databaseWrapper),
      settingsRepo: SettingsRepository(settingsWrapper: widget.settingsWrapper),
      updateHome: () => setState((){}),
    );
  }

  Future<void> initDB() async {
    await widget.databaseWrapper.init();

    if (!mounted) return;
    viewModel.setLoading(false); // triggers rebuild
  }

  @override
  Widget build(BuildContext context) {
    final loadingCircle = const Center(child: CircularProgressIndicator());
    final homeBody = DefaultTabController(
      length: 6, 
      child: Scaffold( 
        appBar: TabBar(
          isScrollable: true,
          tabs: [ 
            Tab(child: SizedBox(width: 100, child: Center(child: Text("Projections")))),
            Tab(child: SizedBox(width: 100, child: Center(child: Text("Calendar")))),
            Tab(child: SizedBox(width: 100, child: Center(child: Text("Accounts")))),
            Tab(child: SizedBox(width: 100, child: Center(child: Text("Income")))),
            Tab(child: SizedBox(width: 100, child: Center(child: Text("Bills")))),
            Tab(text: "⚙"),
          ]
        ),
        body: TabBarView(children: [
          ProjectionsPage(
            repo: viewModel.projectionsRepo, 
            generateProjections: viewModel.generateProjections,
            settingsRepo: viewModel.settingsRepo,
          ),
          CalendarPage(
            projectionsRepo: viewModel.projectionsRepo, 
            generateProjections: viewModel.generateProjections
          ),
          AccountsPage(
            repo: viewModel.accountsRepo, 
            generateProjections: viewModel.generateProjections,
            settingsRepo: viewModel.settingsRepo,
          ),
          IncomePage(
            repo: viewModel.incomeRepo, 
            accountsRepo: viewModel.accountsRepo, 
            generateProjections: viewModel.generateProjections,
            settingsRepo: viewModel.settingsRepo,
          ),
          BillsPage(
            repo: viewModel.billsRepo, 
            accountsRepo: viewModel.accountsRepo, 
            generateProjections: viewModel.generateProjections,
            settingsRepo: viewModel.settingsRepo,
          ),
          SettingsPage(
            getSettings: viewModel.settingsRepo.getSettings,
            saveSettings: viewModel.settingsUpdateHandler,
            saveHandler: viewModel.saveHandler,
            feedbackHandler: viewModel.feedbackHandler,
            backupDataToExcel: viewModel.backup.backupDataToExcel,
            unpackDataFromExcel: viewModel.backup.unpackDataFromExcel,
            exportProjectionToExcel: viewModel.exportProjections.backupDataToExcel,
            checkIfExcelCanExport: viewModel.generateProjections.loadAndValidateAllRecords,
            clearProjections: viewModel.generateProjections.clearProjections,
            generateProjections: viewModel.generateProjections.generateInitialProjections,
            informationPage: InformationPage(),
          ),
        ]),
      )
    ); 

    return MaterialApp(
      title: viewModel.appTitle, 
      theme: ThemeData.light(), 
      darkTheme: ThemeData.dark(),
      themeMode: widget.settingsWrapper.getDarkMode() ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: viewModel.isLoading ? loadingCircle : homeBody,
      ),
    );
  }
}
