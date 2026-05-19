import 'abstract_dao.dart';
import '../models/income_row.dart';

class IncomeDAO extends DAO<IncomeRow>{
  IncomeDAO({required super.dbWrapper}) : 
    super(
      tableName: 'income', 
      fromMap: IncomeRow.fromMap, 
      toMap: IncomeRow.toMap
    );
}