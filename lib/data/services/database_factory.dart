// System
import 'dart:io';
// Dart and Flutter boilerplate
import 'package:flutter/foundation.dart';
// Services
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final String databaseInMemoryPath = inMemoryDatabasePath; // something stupid to change the base name

DatabaseFactory getDatabaseFactory() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactory;
}