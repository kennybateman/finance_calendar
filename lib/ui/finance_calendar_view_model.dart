// System
import 'package:excel/excel.dart';
// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../data/repositories/projections_repository.dart';
import '../data/repositories/accounts_repository.dart';
import '../data/repositories/income_repository.dart';
import '../data/repositories/bills_repository.dart';
import '../data/repositories/settings_repository.dart';
// DOMAIN
import '../domain/use_cases/generate_projections.dart';
import '../domain/use_cases/export_projections.dart';
import '../../domain/use_cases/backup.dart';
import '../domain/models/settings.dart';

// import 'dart:developer' as dev;

class FinanceCalendarViewModel extends ChangeNotifier {
  final String appTitle = "Finance Calendar";

  final BillsRepository billsRepo;
  final IncomeRepository incomeRepo;
  final AccountsRepository accountsRepo;
  final ProjectionsRepository projectionsRepo;
  final SettingsRepository settingsRepo;
  final Future<void> Function(Excel,String) saveHandler;
  final Future<void> Function(BuildContext) feedbackHandler;
  
  final GenerateProjectionsUseCase generateProjections;
  final ExportProjections exportProjections;
  final Backup backup;

  final VoidCallback updateHome;

  FinanceCalendarViewModel({
    required this.saveHandler,
    required this.feedbackHandler,
    required this.billsRepo,
    required this.incomeRepo,
    required this.accountsRepo,
    required this.projectionsRepo,
    required this.settingsRepo,
    required this.updateHome,
  }) :
    generateProjections = GenerateProjectionsUseCase(accountsRepo, billsRepo, incomeRepo, projectionsRepo),
    exportProjections = ExportProjections(projectionsRepo),
    backup = Backup(accountsRepo, billsRepo, incomeRepo);

  /* Methods */

  void settingsUpdateHandler(Settings updatedSettings){
    settingsRepo.updateSettings(updatedSettings);
    updateHome();
  }

  /* state variable tracking */

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  void setLoading(bool value) {
    _isLoading = value;
    updateHome();
  }
}