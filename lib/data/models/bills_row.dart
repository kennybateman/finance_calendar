// ignore_for_file: non_constant_identifier_names
import 'abstract_database_row.dart';

class BillsRow implements DatabaseRow {
  @override final int? pk;
  final String name;
  final int amount;
  final String? due_date;
  final String due_frequency;
  final int? pay_from_account_pk;
  
  BillsRow({
    this.pk,
    required this.name,
    required this.amount,
    required this.due_date,
    required this.due_frequency,
    this.pay_from_account_pk,
  });

  static BillsRow fromMap(Map<String, Object?> map) {
    return BillsRow(
      pk: map['pk'] as int,
      name: map['name'] as String,
      amount: map['amount'] as int,
      due_date: map['due_date'] as String?,
      due_frequency: map['due_frequency'] as String,
      pay_from_account_pk: map['pay_from_account_pk'] as int?,
    );
  }

  static Map<String, Object?> toMap(BillsRow row){
    return { 
      'pk': row.pk, 
      'name': row.name,
      'amount': row.amount,
      'due_date': row.due_date,
      'due_frequency': row.due_frequency,
      'pay_from_account_pk': row.pay_from_account_pk,
    };
  }
}