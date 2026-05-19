import 'abstract_dao.dart';
import '../models/transaction_projections_row.dart';

class TransactionProjectionsDAO extends DAO<TransactionProjectionsRow>{
  TransactionProjectionsDAO({required super.dbWrapper}) : 
    super(
      tableName: 'transaction_projections', 
      fromMap: TransactionProjectionsRow.fromMap, 
      toMap: TransactionProjectionsRow.toMap
    );

  Future<void> deleteAll() async {
    final db = dbWrapper.database;
    db.execute('DELETE FROM $tableName');
    db.rawDelete("DELETE FROM sqlite_sequence WHERE name = '$tableName'");
  }

  Future<List<TransactionProjectionsRow>> getByProjectionPk(int pk) async {
    final db = dbWrapper.database;
    final result = await db.query(tableName,  where: 'projection_pk = ?', whereArgs: [pk], limit: 1);
    return result.map(fromMap).toList();
  }
}