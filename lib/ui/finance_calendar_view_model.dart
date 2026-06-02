// System
import 'package:excel/excel.dart';
// Dart and Flutter
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
import '../domain/use_cases/generate_projections.dart';
import '../domain/use_cases/export_projections.dart';
import '../domain/models/settings.dart';
import '../../domain/use_cases/backup.dart';
// UI
import 'projections/projections_page.dart';
import 'calendar/calendar_page.dart';
import 'accounts/accounts_page.dart';
import 'income/income_page.dart';
import 'bills/bills_page.dart';
import 'settings/settings_page.dart';
import 'information/information_page.dart';

class FinanceCalendarViewModel extends ChangeNotifier {
  final String appTitle = "Finance Calendar";
  late ThemeData themeData;

  final BillsRepository billRepo;
  final IncomeRepository incomeRepo;
  final AccountsRepository accountRepo;
  final ProjectionsRepository projectionsRepo;
  final SettingsRepository settingsRepository;
  final Future<void> Function(Excel,String) saveHandler;
  final Future<void> Function(BuildContext) feedbackHandler;
  late Backup backup;
  
  late DefaultTabController homeBody;
  late Widget loading;
  late GenerateProjectionsUseCase generateProjections;
  late ExportProjections exportProjections;

  FinanceCalendarViewModel(
    DatabaseWrapper databaseWrapper, 
    SettingsWrapper settingsWrapper,
    {
      required this.saveHandler,
      required this.feedbackHandler,
    }
  ) :
    billRepo = BillsRepository(databaseWrapper),  
    incomeRepo = IncomeRepository(databaseWrapper),
    accountRepo = AccountsRepository(databaseWrapper),
    projectionsRepo = ProjectionsRepository(databaseWrapper),
    settingsRepository = SettingsRepository(settingsWrapper: settingsWrapper)
  {

    bool darkMode = false; 
    if (settingsRepository.settingsWrapper.prefs != null){
      darkMode = settingsRepository.getSettings().darkMode;
    }
    themeData = ThemeData(colorScheme: .fromSeed(seedColor: Colors.purple, brightness: darkMode ? Brightness.dark : Brightness.light));

    generateProjections = GenerateProjectionsUseCase(accountRepo, billRepo, incomeRepo, projectionsRepo);

    exportProjections = ExportProjections(projectionsRepo);

    backup = Backup(accountRepo, billRepo, incomeRepo);

    loading = const Center(child: CircularProgressIndicator());
  }


  Widget generateHomeBody(Function updateApp){

    void settingsUpdateHandler(Settings updatedSettings){
      settingsRepository.updateSettings(updatedSettings);
      updateApp();
    }

    homeBody = DefaultTabController(
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
          SettingsPage(
            getSettings: settingsRepository.getSettings,
            saveSettings: settingsUpdateHandler,
            saveHandler: saveHandler,
            feedbackHandler: feedbackHandler,
            backupDataToExcel: backup.backupDataToExcel,
            unpackDataFromExcel: backup.unpackDataFromExcel,
            exportProjectionToExcel: exportProjections.backupDataToExcel,
            checkIfExcelCanExport: generateProjections.loadAndValidateAllRecords,
            informationPage: InformationPage(),
          ),
        ]),
      )
    ); 
    return homeBody;  
  }
}