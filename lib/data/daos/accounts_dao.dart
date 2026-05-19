import 'abstract_dao.dart';
import '../models/accounts_row.dart';

class AccountsDAO extends DAO<AccountsRow>{
  AccountsDAO({required super.dbWrapper}) : 
    super(
      tableName: 'accounts', 
      fromMap: AccountsRow.fromMap, 
      toMap: AccountsRow.toMap
    );
}