import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../services/database_wrapper.dart';
import '../models/abstract_database_row.dart';

abstract class DAO<T extends DatabaseRow> {
  final DatabaseWrapper dbWrapper;
  final String tableName;
  final T Function(Map<String, Object?>) fromMap;
  final Map<String, Object?> Function(T) toMap;

  DAO({required this.dbWrapper, required this.tableName, required this.fromMap, required this.toMap});

  Future<T> create(T row) async {
    final db = dbWrapper.database;
    final id = await db.insert(tableName, toMap(row), conflictAlgorithm: ConflictAlgorithm.fail);
    final result = await db.query(tableName,  where: 'pk = ?', whereArgs: [id]);
    return fromMap(result.first);
  }

  Future<List<T>> getAll() async {
    final db = dbWrapper.database;
    final results = await db.query(tableName);
    return results.map(fromMap).toList();
  }

  Future<T?> get(int pk) async {
    final db = dbWrapper.database;
    final results = await db.query(tableName,  where: 'pk = ?', whereArgs: [pk]);
    return results.map(fromMap).firstOrNull;
  }

  Future<List<T>> getMultiple(List<int> pks) async {
    final db = dbWrapper.database;
    final placeholders = List.filled(pks.length, '?').join(',');
    final results = await db.query(tableName,  where: 'pk in ($placeholders)', whereArgs: pks);
    return results.map(fromMap).toList();   
  }

  Future<List<T>> getAllBy(String field, dynamic value) async {
    final db = dbWrapper.database;
    final results = await db.query(tableName,  where: '$field = ?', whereArgs: [value]);
    return results.map(fromMap).toList();
  }

  Future<T> update(T row) async {
    if (row.pk == null) throw Exception("Cannot update item without pk");

    final db = dbWrapper.database;
    final _ = await db.update(tableName, toMap(row), where: 'pk = ?', whereArgs: [row.pk]);
    final result = await db.query(tableName,  where: 'pk = ?', whereArgs: [row.pk]);
    return fromMap(result.first); 
  }

  Future<void> delete(T row) async {
    if (row.pk == null) throw Exception("Cannot update item without pk");

    final db = dbWrapper.database;
    await db.delete(tableName, where: 'pk = ?', whereArgs: [row.pk]);
  }
}
