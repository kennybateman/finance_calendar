import 'abstract_dao.dart';
import '../models/account_projections_row.dart';

class AccountProjectionsDAO extends DAO<AccountProjectionsRow>{
  AccountProjectionsDAO({required super.dbWrapper}) : 
    super(
      tableName: 'account_projections', 
      fromMap: AccountProjectionsRow.fromMap, 
      toMap: AccountProjectionsRow.toMap
    );

  Future<void> deleteAll() async {
    final db = dbWrapper.database;
    db.execute('DELETE FROM $tableName');
    db.rawDelete("DELETE FROM sqlite_sequence WHERE name = '$tableName'");
  }

  Future<List<AccountProjectionsRow>> getByProjectionPk(int pk) => getAllBy('projection_pk', pk);
}