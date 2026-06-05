import 'abstract_domain_model.dart';
import 'account.dart';
import 'bill.dart';

class BillProjection extends DomainModel<BillProjection> {
  @override
  final int? pk;
  final int? billPk;
  final int? creditAccountPk;
  final int? projectionPk;
  final int projectedAmount;
  final Bill? bill;
  final Account? creditAccount;

  BillProjection({
    this.pk, 
    this.billPk,
    this.creditAccountPk,
    this.projectionPk, 
    required this.projectedAmount,
    this.bill,
    this.creditAccount,
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

  @override
  String toString(){
    if (creditAccount != null){
      return "${creditAccount!.name} interest: \$$projectedAmount";
    }
    return "${bill!.name}: \$$projectedAmount";
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

Map<int, List<BillProjection>> mapBillProjectionsByProjectionPk(List<BillProjection> billProjection){
  Map<int, List<BillProjection>> map = { };
  for (BillProjection row in billProjection){
    if (map.containsKey(row.projectionPk)){
      map[row.projectionPk]!.add(row);
    }
    else{
      map[row.projectionPk!] = [row];
    }
  }
  return map;
}