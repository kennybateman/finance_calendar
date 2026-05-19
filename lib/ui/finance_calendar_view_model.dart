// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../data/services/database_wrapper.dart';
import '../data/repositories/projections_repository.dart';
import '../data/repositories/accounts_repository.dart';
import '../data/repositories/income_repository.dart';
import '../data/repositories/bills_repository.dart';
// DOMAIN
import '../domain/use_cases/generate_projections.dart';
// UI
import 'projections/projections_page.dart';
import 'calendar/calendar_page.dart';
import 'accounts/accounts_page.dart';
import 'income/income_page.dart';
import 'bills/bills_page.dart';

class FinanceCalendarViewModel extends ChangeNotifier {
  final String appTitle = "Finance Calendar";
  final ThemeData themeData = ThemeData(colorScheme: .fromSeed(seedColor: Colors.purple));

  final BillsRepository billRepo;
  final IncomeRepository incomeRepo;
  final AccountsRepository accountRepo;
  final ProjectionsRepository projectionsRepo;
  
  late DefaultTabController homeBody;
  late GenerateProjectionsUseCase generateProjections;

  FinanceCalendarViewModel(DatabaseWrapper databaseWrapper) :
    billRepo = BillsRepository(databaseWrapper),  
    incomeRepo = IncomeRepository(databaseWrapper),
    accountRepo = AccountsRepository(databaseWrapper),
    projectionsRepo = ProjectionsRepository(databaseWrapper)
  {
    generateProjections = GenerateProjectionsUseCase(accountRepo, billRepo, incomeRepo, projectionsRepo);

    homeBody = DefaultTabController(
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
            repo: projectionsRepo, 
            generateProjections: generateProjections
          ),
          CalendarPage(
            projectionsRepo: projectionsRepo, 
            generateProjections: generateProjections
          ),
          AccountsPage(
            repo: accountRepo, 
            generateProjections: generateProjections
          ),
          IncomePage(
            repo: incomeRepo, 
            accountsRepo: accountRepo, 
            generateProjections: generateProjections
          ),
          BillsPage(
            repo: billRepo, 
            accountsRepo: accountRepo, 
            generateProjections: generateProjections
          ),
        ]),
      )
    );
  }
}