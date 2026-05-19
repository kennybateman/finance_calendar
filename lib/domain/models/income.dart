import 'abstract_domain_model.dart';
import 'account.dart';

class Income implements DomainModel {
  @override
  final int? pk;
  final String name;
  final int amount;
  final DateTime? dueDate;
  final String dueFrequency;
  final int? payToAccountPk;
  final Account? payToAccount;
  
  Income({ this.pk, 
    required this.name, 
    required this.amount, 
    required this.dueDate, 
    required this.dueFrequency, 
    required this.payToAccountPk,
    this.payToAccount});

  bool keyFieldsChanged(Income other){
    return amount != other.amount ||
    dueDate != other.dueDate ||
    dueFrequency != other.dueFrequency ||
    payToAccountPk != other.payToAccountPk;  
  }

  @override
  bool operator ==(Object other){
    // If same memory object: true
    if (identical(this, other)) return true;
    // If not same type: false
    if (other is! Income) return false;
    // If all properties match: true
    return pk == other.pk && 
      name == other.name &&
      amount == other.amount &&
      dueDate == other.dueDate &&
      dueFrequency == other.dueFrequency &&
      payToAccountPk == other.payToAccountPk;
  }

  @override
  int get hashCode => Object.hashAll([
    pk,
    name,
    amount,
    dueDate,
    dueFrequency,
    payToAccountPk,
  ]);

  static Income createNewTemp(){
    return Income(
      name: "income", 
      amount: 0, 
      dueDate: null, 
      dueFrequency: 'biweekly', 
      payToAccountPk: null);
  }

  Income updateValue({
    int? pk,
    String? name,
    int? amount,
    DateTime? dueDate,
    String? dueFrequency,
    int? payToAccountPk}){
    return Income(
      pk: pk ?? this.pk,
      name: name ?? this.name, 
      amount: amount ?? this.amount, 
      dueDate: dueDate ?? this.dueDate, 
      dueFrequency: dueFrequency ?? this.dueFrequency, 
      payToAccountPk: payToAccountPk ?? this.payToAccountPk);
  }

  Income joinPayToAccount(Account? payToAccount){
    return Income(
      pk: pk,
      name: name,
      amount: amount,
      dueDate: dueDate,
      dueFrequency: dueFrequency,
      payToAccountPk: payToAccountPk,
      payToAccount: payToAccount
    );
  }
}
