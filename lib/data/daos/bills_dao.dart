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
}