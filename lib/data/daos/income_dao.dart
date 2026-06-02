import 'abstract_dao.dart';
import '../models/income_row.dart';

class IncomeDAO extends DAO<IncomeRow>{
  IncomeDAO({
    required super.dbWrapper
  }) : 
    super(
      tableName: 'income', 
      fromMap: IncomeRow.fromMap, 
      toMap: IncomeRow.toMap
    );

  Future<List<({int pk, String name})>> getAllNames() async {
    final allIncome = await getAll(); // don't fetch individual fields, always fetch the whole row.
    return allIncome.map((i) => (pk: i.pk!, name: i.name)).toList();
  }

  Future<void> deleteAll() async {
    final db = dbWrapper.database;
    await db.execute('DELETE FROM $tableName');
    await db.rawDelete("DELETE FROM sqlite_sequence WHERE name = '$tableName'");
  }
}