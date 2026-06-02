import 'abstract_dao.dart';
import '../models/bills_row.dart';

class BillsDAO extends DAO<BillsRow>{
  BillsDAO({
    required super.dbWrapper
  }) : 
    super(
      tableName: 'bills', 
      fromMap: BillsRow.fromMap, 
      toMap: BillsRow.toMap
    );

  Future<List<(int,String)>> getAllNames() async {
    final allBills = await getAll(); // don't fetch individual fields, always fetch the whole row.
    return allBills.map((b) => (b.pk!, b.name)).toList();
  }

  Future<void> deleteAll() async {
    final db = dbWrapper.database;
    await db.execute('DELETE FROM $tableName');
    await db.rawDelete("DELETE FROM sqlite_sequence WHERE name = '$tableName'");
  }
}