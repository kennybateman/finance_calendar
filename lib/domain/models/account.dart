import 'abstract_domain_model.dart';

class Account implements DomainModel {
  @override
  final int? pk;
  final String name;
  final int balance;
  final DateTime? balanceDate;
  final String accountType;
  final int creditLimit;
  final int interest;
  final String dueFrequency;
  final DateTime? dueDate;
  final int? payFromAccountPk;
  final Account? payFromAccount;
  final bool payFromThisAccount;
  
  Account({
    this.pk, 
    required this.name, 
    required this.balance, 
    required this.balanceDate, 
    required this.accountType, 
    this.creditLimit = 0,
    this.interest = 0,
    this.dueFrequency = 'monthly',
    this.dueDate,
    this.payFromAccountPk,
    this.payFromAccount,
  }) : payFromThisAccount = pk == payFromAccountPk; // the way this is coded 

  @override
  bool operator ==(Object other){
    // If same memory object: true
    if (identical(this, other)) return true;
    // If not same type: false
    if (other is! Account) return false;
    // If all properties match: true
    return pk == other.pk && 
      name == other.name &&
      balance == other.balance &&
      balanceDate == other.balanceDate &&
      accountType == other.accountType &&
      creditLimit == other.creditLimit &&
      interest == other.interest &&
      dueFrequency == other.dueFrequency &&
      dueDate == other.dueDate &&
      payFromAccountPk == other.payFromAccountPk;
  }

  @override
  int get hashCode => Object.hashAll([
    pk,
    name,
    balance,
    balanceDate,
    accountType,
    creditLimit,
    interest,
    dueFrequency,
    dueDate,
    payFromAccountPk
  ]);

  static Account createNewTemp(){
    return Account(
      name: 'new account', 
      balance: 0, 
      balanceDate: null, 
      accountType: 'debit', 
      creditLimit: 0,
      interest: 0,
      dueFrequency: 'monthly',
      dueDate: null,
      payFromAccountPk: null,
    );
  }

  Account updateValue({
    int? pk, 
    String? name,
    int? balance,
    DateTime? balanceDate,
    String? accountType,
    int? creditLimit,
    int? interest,
    String? dueFrequency,
    DateTime? dueDate,
    int? payFromAccountPk,
    bool? payFromThisAccount}){
    return Account(
      pk: pk ?? this.pk,
      name: name ?? this.name, 
      balance: balance ?? this.balance, 
      balanceDate: balanceDate ?? this.balanceDate, 
      accountType: accountType ?? this.accountType, 
      creditLimit: creditLimit ?? this.creditLimit,
      interest: interest ?? this.interest,
      dueFrequency: dueFrequency ?? this.dueFrequency,
      dueDate: dueDate ?? this.dueDate,
      payFromAccountPk: payFromAccountPk ?? this.payFromAccountPk,
    );  
  }

  bool keyFieldsChanged(Account other){
    return balance != other.balance ||
    balanceDate != other.balanceDate ||
    accountType != other.accountType ||
    creditLimit != other.creditLimit ||
    interest != other.interest ||
    dueFrequency != other.dueFrequency ||
    dueDate == other.dueDate ||
    payFromAccountPk != other.payFromAccountPk;  
  }

  Account joinPayFromAccount(Account? payFromAccount){
    return Account(
      pk: pk,
      name: name,
      balance: balance,
      balanceDate: balanceDate,
      accountType: accountType,
      creditLimit: creditLimit,
      interest: interest,
      dueFrequency: dueFrequency,
      dueDate: dueDate,
      payFromAccountPk: payFromAccountPk,
      payFromAccount: payFromAccount,
    );
  }
}
