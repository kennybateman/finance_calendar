// ignore_for_file: non_constant_identifier_names
import 'abstract_database_row.dart';

class AccountsRow implements DatabaseRow {
  @override final int? pk;
  final String name;
  final int balance;
  final String? balance_date;
  final String account_type;
  final int? credit_limit;
  final int? interest;
  final String? due_date;
  final int? due_date_anchor_day;
  final String? due_frequency;
  final int? pay_from_account_pk;
  
  AccountsRow({
    this.pk,
    required this.name,
    required this.balance,
    required this.balance_date,
    required this.account_type,
    this.credit_limit,
    this.interest,
    this.due_date,
    required this.due_date_anchor_day,
    this.due_frequency,
    this.pay_from_account_pk,
  });

  static AccountsRow fromMap(Map<String, Object?> map) {
    return AccountsRow(
      pk: map['pk'] as int,
      name: map['name'] as String,
      balance: map['balance'] as int,
      balance_date: map['balance_date'] as String?,
      account_type: map['account_type'] as String,
      credit_limit: map['credit_limit'] as int?,
      interest: map['interest'] as int?,
      due_date: map['due_date'] as String?,
      due_date_anchor_day: map['due_date_anchor_day'] as int?,
      due_frequency: map['due_frequency'] as String?,
      pay_from_account_pk: map['pay_from_account_pk'] as int?,
    );
  }

  static Map<String, Object?> toMap(AccountsRow row){
    return { 
      'pk': row.pk, 
      'name': row.name,
      'balance': row.balance,
      'balance_date': row.balance_date,
      'account_type': row.account_type,
      'credit_limit': row.credit_limit,
      'interest': row.interest,
      'due_date': row.due_date,
      'due_date_anchor_day': row.due_date_anchor_day,
      'due_frequency': row.due_frequency,
      'pay_from_account_pk': row.pay_from_account_pk,
    };
  }

  AccountsRow updateValue({
    int? pk, 
    String? name,
    int? balance,
    String? balance_date,
    String? account_type,
    int? credit_limit,
    int? interest,
    String? due_frequency,
    String? due_date,
    int? due_date_anchor_day,
    int? pay_from_account_pk}){
    return AccountsRow(
      pk: pk ?? this.pk,
      name: name ?? this.name, 
      balance: balance ?? this.balance, 
      balance_date: balance_date ?? this.balance_date, 
      account_type: account_type ?? this.account_type, 
      credit_limit: credit_limit ?? this.credit_limit,
      interest: interest ?? this.interest,
      due_frequency: due_frequency ?? this.due_frequency,
      due_date: due_date ?? this.due_date,
      due_date_anchor_day: due_date_anchor_day ?? this.due_date_anchor_day,
      pay_from_account_pk: pay_from_account_pk ?? this.pay_from_account_pk,
    );  
  }
}