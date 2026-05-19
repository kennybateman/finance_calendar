// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../data/repositories/projections_repository.dart';
import '../data/repositories/accounts_repository.dart';
import '../data/repositories/income_repository.dart';
import '../data/repositories/bills_repository.dart';
import '../data/services/database_wrapper.dart';
// import '../data/services/database_schema.dart';
// import '../data/services/database_factory.dart';
// import '../data/repositories/accounts_repository.dart';
// import '../data/repositories/income_repository.dart';
// import '../data/repositories/bills_repository.dart';
// import '../data/repositories/projections_repository.dart';
// DOMAIN
import '../domain/use_cases/generate_projections.dart';
// UI
import 'projections/projections_page.dart';
import 'calendar/calendar_page.dart';
import 'accounts/accounts_page.dart';
import 'income/income_page.dart';
import 'bills/bills_page.dart';

class FinanceCalendar extends StatefulWidget {
  final DatabaseWrapper dbProvider;
  final FinanceCalendarViewModel viewModel;
  FinanceCalendar({ super.key, required this.dbProvider }) : 
    viewModel = FinanceCalendarViewModel(dbProvider);

  @override
  State<FinanceCalendar> createState() => FinanceCalendarState();
}

class FinanceCalendarState extends State<FinanceCalendar>{
  late bool dbIsInitialized;

  @override
  void initState() {
    super.initState();
    initDB();
  }

  Future<void> initDB() async {
    setState((){
      dbIsInitialized = false;
    });
    await widget.viewModel.initDB();
    setState((){
      dbIsInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    /* as long as db isn't initalized yet, only display this */
    final circleWaiting = const Center(child: CircularProgressIndicator());
    /* main display page, don't declare this inline, too nested */
    final homeBody = DefaultTabController(
      length: 5, 
      child: Scaffold( 
        appBar: TabBar(tabs: [ 
          Tab(text: "Projections"),
          Tab(text: "Calendar"),
          Tab(text: "Accounts"),
          Tab(text: "Income"),
          Tab(text: "Bills"),
        ]),
        body: TabBarView(children: [
          ProjectionsPage(
            repo: widget.viewModel.projectionsRepo, 
            generateProjections: widget.viewModel.generateProjections),
          CalendarPage(
            projectionsRepo: widget.viewModel.projectionsRepo, 
            generateProjections: widget.viewModel.generateProjections),
          AccountsPage(
            repo: widget.viewModel.accountRepo, 
            generateProjections: widget.viewModel.generateProjections),
          IncomePage(
            repo: widget.viewModel.incomeRepo, 
            accountsRepo: widget.viewModel.accountRepo, 
            generateProjections: widget.viewModel.generateProjections),
          BillsPage(
            repo: widget.viewModel.billRepo, 
            accountsRepo: widget.viewModel.accountRepo, 
            generateProjections: widget.viewModel.generateProjections), 
        ]),
      )
    );
            
    return MaterialApp(
      title: widget.viewModel.appTitle, 
      theme: widget.viewModel.themeData, 
      home: Scaffold(
        appBar: AppBar(),
        body: dbIsInitialized ? homeBody : circleWaiting,
      ),
    );
  }
}

class FinanceCalendarViewModel extends ChangeNotifier {
  final String appTitle = "Finance Calendar";
  final ThemeData themeData = ThemeData(colorScheme: .fromSeed(seedColor: Colors.purple));

  final DatabaseWrapper databaseWrapper;

  final BillsRepository billRepo;
  final IncomeRepository incomeRepo;
  final AccountsRepository accountRepo;
  final ProjectionsRepository projectionsRepo;
  
  late GenerateProjectionsUseCase generateProjections;

  /* required arguments */
  FinanceCalendarViewModel(this.databaseWrapper) :
    billRepo = BillsRepository(databaseWrapper),  /* final initializers */
    incomeRepo = IncomeRepository(databaseWrapper),
    accountRepo = AccountsRepository(databaseWrapper),
    projectionsRepo = ProjectionsRepository(databaseWrapper)
  {
    generateProjections = GenerateProjectionsUseCase(accountRepo, billRepo, incomeRepo, projectionsRepo); /* late construction */
  }

  Future<void> initDB() async {
    await databaseWrapper.init();
  }
}