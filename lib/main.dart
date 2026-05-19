// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import 'data/services/database_wrapper.dart';
import 'data/services/database_schema.dart';
import 'data/services/database_factory.dart';
// UI
import 'ui/finance_calendar.dart';

void main() async {
  /* SYSTEM */
  final factory = getDatabaseFactory();

  /* SERVICE (SQFLITE) */
  final database = DatabaseWrapper(dbFileName: 'finance_calendar.db', schema: DatabaseSchema(), dbFactory: factory);

  /* APP and UI */
  runApp(FinanceCalendar(databaseWrapper: database));
}
