// System
import 'package:path/path.dart';
// Services
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
// Data
import 'database_schema.dart';

class DatabaseWrapper {
  final String dbFileName;
  final Future<String> Function() pathProvider;
  final DatabaseSchema schema;
  final DatabaseFactory dbFactory;

  DatabaseWrapper({
    required this.dbFileName,
    required this.schema,
    required this.dbFactory,
    Future<String> Function()? pathProvider,
  }) : pathProvider = pathProvider ?? dbFactory.getDatabasesPath;

  Database? _database;
  Database get database {
    final db = _database;
    if (db == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return db;
  }
  
  Future<void> init() async {
    if (_database != null) return;

    final String path;
    if (dbFileName == inMemoryDatabasePath){
      path = dbFileName;
    }
    else{
      final dbPath = await pathProvider();
      path = join(dbPath, dbFileName); 
    }

    _database = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: schema.createDB,
        onUpgrade: schema.onUpgrade,
      ),
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
  }
}