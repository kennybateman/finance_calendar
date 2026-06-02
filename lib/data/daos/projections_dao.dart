import 'abstract_dao.dart';
import '../models/projections_row.dart';

class ProjectionsDAO extends DAO<ProjectionsRow>{
  ProjectionsDAO({required super.dbWrapper}) : 
    super(
      tableName: 'projections', 
      fromMap: ProjectionsRow.fromMap, 
      toMap: ProjectionsRow.toMap
    );

  Future<void> deleteAll() async {
    final db = dbWrapper.database;
    await db.execute('DELETE FROM $tableName');
    await db.rawDelete("DELETE FROM sqlite_sequence WHERE name = '$tableName'");
  }

  Future<ProjectionsRow?> getByDate(String dateString) async {
    final db = dbWrapper.database;
    final result = (await db.query(tableName,  where: 'date = ?', whereArgs: [dateString], limit: 1)).firstOrNull;
    if (result == null) return null;
    return fromMap(result);
  }

  Future<List<ProjectionsRow>> getByDateRange(String start, String end) async {
    final db = dbWrapper.database;
    final results = await db.query(tableName,  where: 'date BETWEEN ? AND ?', whereArgs: [start, end]);
    if (results.isEmpty) return [];
    return results.map(fromMap).toList();
  }
}