import 'abstract_domain_model.dart';
import 'account.dart';
import 'bill.dart';
import 'income.dart';

class Projection extends DomainModel<Projection> {
  @override 
  final int? pk;
  final DateTime date;
  Projection({
    this.pk, 
    required this.date, 
  });

  /* These need to be manually loaded */
  List<AccountProjection> accountProjections = [];
  Map<int?, AccountProjection?>? accountProjectionsByAccountPk;

  List<BillProjection> billProjections = [];
  List<IncomeProjection> incomeProjections = [];

  void addAccountProjection(AccountProjection ap){
    accountProjections.add(ap);
    accountProjectionsByAccountPk = mapAccountProjectionsByAccountPk(accountProjections);
  }

  void addBillProjection(BillProjection bp){
    billProjections.add(bp);
  }

  void addIncomeProjection(IncomeProjection ip){
    incomeProjections.add(ip);
  }

  @override
  bool operator ==(Object other){
    // If same memory object: true
    if (identical(this, other)) return true;
    // If not same type: false
    if (other is! Projection) return false;
    // If all properties match: true
    return pk == other.pk && 
      date == other.date;
  }

  @override
  int get hashCode => Object.hashAll([
    pk,
    date,
  ]);

  @override
  bool keyFieldsChanged(Projection other){
    throw Exception("not implemented");  
  }

  Projection createNewWithDate(DateTime date){
    return Projection(date: date);
  }
}

class AccountProjection extends DomainModel<AccountProjection>{
  @override
  final int? pk;
  final int accountPk;
  final int? projectionPk;
  final int projectedBalance;
  final Account? account;
  final Projection? projection;

  AccountProjection({
    this.pk, 
    required this.accountPk,
    this.projectionPk,
    required this.projectedBalance,
    this.account,
    this.projection,
  });

  @override
  bool operator ==(Object other){
    // If same memory object: true
    if (identical(this, other)) return true;
    // If not same type: false
    if (other is! AccountProjection) return false;
    // If all properties match: true
    return pk == other.pk &&
      accountPk == other.accountPk &&
      projectionPk == other.projectionPk &&
      projectedBalance == other.projectedBalance;
  }

  @override
  int get hashCode => Object.hashAll([
    pk,
    accountPk,
    projectionPk,
    projectedBalance,
  ]);

  @override
  bool keyFieldsChanged(AccountProjection other){
    throw Exception("not implemented");  
  }

  AccountProjection updateValues({
    int? pk,
    int? projectedBalance,
    int? projectionPk,
    int? accountPk}){
    return AccountProjection(
      pk: pk ?? this.pk,
      projectedBalance: projectedBalance ?? this.projectedBalance, 
      projectionPk: projectionPk ?? this.projectionPk, 
      accountPk: accountPk ?? this.accountPk);
  }
}

Map<int?, AccountProjection?> mapAccountProjectionsByAccountPk(List<AccountProjection> accountProjections){
  Map<int?, AccountProjection?> map = { null: null };
  for (AccountProjection record in accountProjections){
    map[record.accountPk] = record;
  }
  return map;
}

class BillProjection extends DomainModel<BillProjection> {
  @override
  final int? pk;
  final int? billPk;
  final int? creditAccountPk;
  final int? projectionPk;
  final int projectedAmount;
  final Bill? bill;
  final Account? creditAccount;
  final Projection? projection;

  BillProjection({
    this.pk, 
    this.billPk,
    this.creditAccountPk,
    this.projectionPk, 
    required this.projectedAmount,
    this.bill,
    this.creditAccount,
    this.projection,
  });

  @override
  bool operator ==(Object other){ // MUST UPDATE THIS WITH LATEST PROPERTIES LIKE creditAccountPK
    // If same memory object: true
    if (identical(this, other)) return true;
    // If not same type: false
    if (other is! BillProjection) return false;
    // If all properties match: true
    return pk == other.pk &&
      billPk == other.billPk &&
      creditAccountPk == other.creditAccountPk &&
      projectionPk == other.projectionPk &&
      projectedAmount == other.projectedAmount;
  }

  @override
  int get hashCode => Object.hashAll([
    pk,
    billPk,
    creditAccountPk,
    projectionPk,
    projectedAmount,
  ]);

  @override
  bool keyFieldsChanged(BillProjection other){
    throw Exception("not implemented");  
  }

  BillProjection updateValues({
    int? pk,
    int? projectedAmount,
    int? projectionPk,
    int? billPk,
    int? creditAccountPk}){
    return BillProjection(
      pk: pk ?? this.pk,
      projectedAmount: projectedAmount ?? this.projectedAmount, 
      projectionPk: projectionPk ?? this.projectionPk, 
      billPk: billPk ?? this.billPk,
      creditAccountPk: creditAccountPk ?? this.creditAccountPk);
  }
}

class IncomeProjection extends DomainModel<IncomeProjection>{
  @override
  final int? pk;
  final int incomePk;
  final int? projectionPk;
  final int projectedAmount;
  final Income? income;
  final Projection? projection;
  
  IncomeProjection({
    this.pk, 
    required this.incomePk, 
    this.projectionPk,
    required this.projectedAmount,
    this.income,
    this.projection,
  });

  @override
  bool operator ==(Object other){
    // If same memory object: true
    if (identical(this, other)) return true;
    // If not same type: false
    if (other is! IncomeProjection) return false;
    // If all properties match: true
    return pk == other.pk &&
      incomePk == other.incomePk &&
      projectionPk == other.projectionPk &&
      projectedAmount == other.projectedAmount;
  }

  @override
  int get hashCode => Object.hashAll([
    pk,
    incomePk,
    projectionPk,
    projectedAmount,
  ]);

  @override
  bool keyFieldsChanged(IncomeProjection other){
    throw Exception("not implemented");  
  }

  IncomeProjection updateValues({
    int? pk,
    int? projectedAmount,
    int? projectionPk,
    int? incomePk}){
    return IncomeProjection(
      pk: pk ?? this.pk,
      projectedAmount: projectedAmount ?? this.projectedAmount, 
      projectionPk: projectionPk ?? this.projectionPk, 
      incomePk: incomePk ?? this.incomePk);
  }
}
