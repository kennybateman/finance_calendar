// ignore_for_file: non_constant_identifier_names
import 'abstract_database_row.dart';

class AccountProjectionsRow implements DatabaseRow {
  @override final int? pk;
  final int projected_balance;
  final int projection_pk;
  final int account_pk;

  AccountProjectionsRow({
    this.pk,
    required this.projected_balance,
    required this.projection_pk,
    required this.account_pk
  });

  static AccountProjectionsRow fromMap(Map<String, Object?> map) {
    return AccountProjectionsRow(
      pk: map['pk'] as int,
      projected_balance: map['projected_balance'] as int,
      projection_pk: map['projection_pk'] as int,
      account_pk: map['account_pk'] as int,
    );
  }

  static Map<String, Object?> toMap(AccountProjectionsRow row){
    return { 
      'pk': row.pk, 
      'projected_balance': row.projected_balance,
      'projection_pk': row.projection_pk,
      'account_pk': row.account_pk,
    };
  }
}

// /* Implement your own unique supporting methods */
// Map<int, List<AccountProjectionsRow>> mapAccountProjectionsByProjectionPk(List<AccountProjectionsRow> accountProjectionRows){
//   Map<int, List<AccountProjectionsRow>> map = { };
//   for (AccountProjectionsRow row in accountProjectionRows){
//     if (map.containsKey(row.projection_pk)){
//       map[row.projection_pk]!.add(row);
//     }
//     else{
//       map[row.projection_pk] = [row];
//     }
//   }
//   return map;
// }

// /* Implement your own unique supporting methods */
// Map<int, AccountProjectionsRow> mapAccountProjectionsByAccountPk(List<AccountProjectionsRow> accountProjectionRows){
//   Map<int, AccountProjectionsRow> map = { };
//   for (AccountProjectionsRow row in accountProjectionRows){
//       map[row.projection_pk] = row;
//   }
//   return map;
// }