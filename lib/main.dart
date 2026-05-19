// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import 'data/services/database_wrapper.dart';
import 'data/services/database_schema.dart';
import 'data/services/database_factory.dart';
// import 'data/repositories/accounts_repository.dart';
// import 'data/repositories/income_repository.dart';
// import 'data/repositories/bills_repository.dart';
// import 'data/repositories/projections_repository.dart';
// UI
import 'ui/finance_calendar.dart';

void main() async {
  /* SYSTEM */
  final factory = getDatabaseFactory();

  /* SERVICES */
  final dbProvider = DatabaseWrapper(dbFileName: 'finance_calendar.db', schema: DatabaseSchema(), dbFactory: factory);

  /* APP and UI */
  runApp(FinanceCalendar(dbProvider: dbProvider));
}
