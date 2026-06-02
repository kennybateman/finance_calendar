// System
import 'dart:io';
import 'package:excel/excel.dart';
// Dart and Flutter
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// DATA
import 'data/services/database_wrapper.dart';
import 'data/services/settings_wrapper.dart';
import 'data/services/database_schema.dart';
import 'data/services/database_factory.dart';
// DOMAIN
import 'domain/use_cases/save_handler.dart';
import 'domain/use_cases/feedback_handler.dart';
// UI
import 'ui/finance_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /* SYSTEM */
  final factory = getDatabaseFactory(); // does something different for desktop vs mobile

  /* SERVICES */
  final database = DatabaseWrapper(dbFileName: 'finance_calendar.db', schema: DatabaseSchema(), dbFactory: factory);
  final settings = SettingsWrapper();
  await settings.init();

  /* Desktop usually have different save conventions than mobile */
  Future<void> Function(Excel,String) saveHandler;
  Future<void> Function(BuildContext) feedbackHandler;
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    saveHandler = SaveHandler.saveExcelDesktop;
    feedbackHandler = FeedbackHandler.feedbackHandlerDesktop;
  }else{
    saveHandler = SaveHandler.saveExcelMobile;
    feedbackHandler = FeedbackHandler.feedbackHandlerMobile;
  }

  /* APP and UI */
  runApp(FinanceCalendar(
    databaseWrapper: database, 
    settingsWrapper: settings, 
    saveHandler: saveHandler,
    feedbackHandler: feedbackHandler,
  ));
}
