import 'abstract_dao.dart';
import '../models/bills_row.dart';

class BillsDAO extends DAO<BillsRow>{
  BillsDAO({required super.dbWrapper}) : 
    super(
      tableName: 'bills', 
      fromMap: BillsRow.fromMap, 
      toMap: BillsRow.toMap
    );
}