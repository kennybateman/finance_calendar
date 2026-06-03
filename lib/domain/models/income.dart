import 'abstract_domain_model.dart';
import 'account.dart';

class Income extends DomainModel<Income> {
  @override
  final int? pk;
  final String name;
  final int amount;
  final DateTime? dueDate;
  final int? dueDateAnchorDay;
  final String dueFrequency;
  final int? payToAccountPk;
  final Account? payToAccount;
  
  Income({ this.pk, 
    required this.name, 
    required this.amount, 
    this.dueDate,
    this.dueDateAnchorDay,
    required this.dueFrequency, 
    this.payToAccountPk,
    this.payToAccount
  });

  @override
  bool keyFieldsChanged(Income other){
    return amount != other.amount ||
    dueDate != other.dueDate ||
    dueFrequency != other.dueFrequency ||
    dueDateAnchorDay == other.dueDateAnchorDay ||
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
      dueDateAnchorDay == other.dueDateAnchorDay &&
      payToAccountPk == other.payToAccountPk;
  }

  @override
  int get hashCode => Object.hashAll([
    pk,
    name,
    amount,
    dueDate,
    dueFrequency,
    dueDateAnchorDay,
    payToAccountPk,
  ]);

  Income updateValue({
    int? pk,
    String? name,
    int? amount,
    DateTime? dueDate,
    int? dueDateAnchorDay,
    String? dueFrequency,
    int? payToAccountPk}){
    return Income(
      pk: pk ?? this.pk,
      name: name ?? this.name, 
      amount: amount ?? this.amount, 
      dueDate: dueDate ?? this.dueDate, 
      dueDateAnchorDay: dueDateAnchorDay ?? this.dueDateAnchorDay,
      dueFrequency: dueFrequency ?? this.dueFrequency, 
      payToAccountPk: payToAccountPk ?? this.payToAccountPk);
  }

  Income joinPayToAccount(Account? payToAccount){
    return Income(
      pk: pk,
      name: name,
      amount: amount,
      dueDate: dueDate,
      dueDateAnchorDay: dueDateAnchorDay,
      dueFrequency: dueFrequency,
      payToAccountPk: payToAccountPk,
      payToAccount: payToAccount
    );
  }

  Income clearPk(){
    return Income(
      pk: null,
      name: name,
      amount: amount,
      dueDate: dueDate,
      dueDateAnchorDay: dueDateAnchorDay,
      dueFrequency: dueFrequency,
      payToAccountPk: payToAccountPk,
      payToAccount: payToAccount
    );
  }
}
