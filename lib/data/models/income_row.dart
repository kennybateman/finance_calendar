// ignore_for_file: non_constant_identifier_names
import 'abstract_database_row.dart';

class IncomeRow implements DatabaseRow {
  @override final int? pk;
  final String name;
  final int amount;
  final String? due_date;
  final String due_frequency;
  final int? pay_to_account_pk;
  
  IncomeRow({
    this.pk,
    required this.name,
    required this.amount,
    required this.due_date,
    required this.due_frequency,
    this.pay_to_account_pk,
  });

  static IncomeRow fromMap(Map<String, Object?> map) {
    return IncomeRow(
      pk: map['pk'] as int,
      name: map['name'] as String,
      amount: map['amount'] as int,
      due_date: map['due_date'] as String?,
      due_frequency: map['due_frequency'] as String,
      pay_to_account_pk: map['pay_to_account_pk'] as int?,
    );
  }

  static Map<String, Object?> toMap(IncomeRow row){
    return { 
      'pk': row.pk, 
      'name': row.name,
      'amount': row.amount,
      'due_date': row.due_date,
      'due_frequency': row.due_frequency,
      'pay_to_account_pk': row.pay_to_account_pk,
    };
  }
}