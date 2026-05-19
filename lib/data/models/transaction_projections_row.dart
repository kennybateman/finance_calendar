// ignore_for_file: non_constant_identifier_names
import 'abstract_database_row.dart';

class TransactionProjectionsRow implements DatabaseRow {
  @override final int? pk;
  final int projected_amount;
  final int projection_pk;
  final int? bill_pk;
  final int? income_pk;
  final int? account_pk;
  
  TransactionProjectionsRow({
    this.pk,
    required this.projected_amount,
    required this.projection_pk,
    this.bill_pk,
    this.income_pk,
    this.account_pk
  });

  static TransactionProjectionsRow fromMap(Map<String, Object?> map) {
    return TransactionProjectionsRow(
      pk: map['pk'] as int,
      projected_amount: map['projected_amount'] as int,
      projection_pk: map['projection_pk'] as int,
      bill_pk: map['bill_pk'] as int?,
      income_pk: map['income_pk'] as int?,
      account_pk: map['account_pk'] as int?,
    );
  }

  static Map<String, Object?> toMap(TransactionProjectionsRow row){
    return { 
      'pk': row.pk, 
      'projected_amount': row.projected_amount,
      'projection_pk': row.projection_pk,
      'bill_pk': row.bill_pk,
      'income_pk': row.income_pk,
      'account_pk': row.account_pk,
    };
  }
}

/* Implement your own unique supporting methods */
Map<int, List<TransactionProjectionsRow>> mapTransactionProjectionsByProjectionPk(List<TransactionProjectionsRow> accountProjectionRows){
  Map<int, List<TransactionProjectionsRow>> map = { };
  for (TransactionProjectionsRow row in accountProjectionRows){
    if (map.containsKey(row.projection_pk)){
      map[row.projection_pk]!.add(row);
    }
    else{
      map[row.projection_pk] = [row];
    }
  }
  return map;
}

/* Implement your own unique supporting methods */
Map<int, TransactionProjectionsRow> mapAccountProjectionsByAccountPk(List<TransactionProjectionsRow> accountProjectionRows){
  Map<int, TransactionProjectionsRow> map = { };
  for (TransactionProjectionsRow row in accountProjectionRows){
      map[row.projection_pk] = row;
  }
  return map;
}