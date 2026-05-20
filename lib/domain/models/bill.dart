import 'abstract_domain_model.dart';
import 'account.dart';

class Bill extends DomainModel<Bill>{
  @override
  final int? pk;
  final String name;
  final int amount;
  final DateTime? dueDate; 
  final String dueFrequency;
  final int? payFromAccountPk;
  final Account? payFromAccount;
  Bill({
    this.pk, 
    required this.name, 
    required this.amount, 
    this.dueDate, 
    required this.dueFrequency, 
    this.payFromAccountPk,
    this.payFromAccount,
  });

  @override
  bool operator ==(Object other){
    // If same memory object: true
    if (identical(this, other)) return true;
    // If not same type: false
    if (other is! Bill) return false;
    // If all properties match: true
    return pk == other.pk && 
      name == other.name &&
      amount == other.amount &&
      dueDate == other.dueDate &&
      dueFrequency == other.dueFrequency &&
      payFromAccountPk == other.payFromAccountPk;
  }

  @override
  bool keyFieldsChanged(Bill other){
    return amount != other.amount ||
    dueDate != other.dueDate ||
    dueFrequency != other.dueFrequency ||
    payFromAccountPk != other.payFromAccountPk;  
  }

  @override
  int get hashCode => Object.hashAll([
    pk,
    name,
    amount,
    dueDate,
    dueFrequency,
    payFromAccountPk,
  ]);

  static Bill createNewTemp(){
    return Bill(
      name: "bill", 
      amount: 0, 
      dueDate: null, 
      dueFrequency: 'monthly', 
      payFromAccountPk: null);
  }

  Bill updateValue({
    int? pk,
    String? name,
    int? amount,
    DateTime? dueDate,
    String? dueFrequency,
    int? payFromAccountPk}){
    return Bill(
      pk: pk ?? this.pk,
      name: name ?? this.name, 
      amount: amount ?? this.amount, 
      dueDate: dueDate ?? this.dueDate, 
      dueFrequency: dueFrequency ?? this.dueFrequency, 
      payFromAccountPk: payFromAccountPk ?? this.payFromAccountPk);
  }

  Bill joinPayFromAccount(Account? payFromAccount){
    return Bill(
      pk: pk,
      name: name,
      amount: amount,
      dueDate: dueDate,
      dueFrequency: dueFrequency,
      payFromAccountPk: payFromAccountPk,
      payFromAccount: payFromAccount,
    );
  }
}
