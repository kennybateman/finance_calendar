import 'abstract_dao.dart';
import '../models/accounts_row.dart';

class AccountsDAO extends DAO<AccountsRow>{
  AccountsDAO({
    required super.dbWrapper
  }) : 
    super(
      tableName: 'accounts', 
      fromMap: AccountsRow.fromMap, 
      toMap: AccountsRow.toMap
    );

  Future<List<({int pk, String name})>> getAllNames() async {
    final allAccounts = await getAll(); // don't fetch individual fields, always fetch the whole row.
    return allAccounts.map((a) => (pk: a.pk!, name: a.name)).toList();
  }
}