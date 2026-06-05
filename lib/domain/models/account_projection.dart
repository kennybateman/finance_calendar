import 'abstract_domain_model.dart';
import 'account.dart';
import 'projection.dart';

class AccountProjection extends DomainModel<AccountProjection>{
  @override
  final int? pk;
  final int accountPk;
  final int? projectionPk;
  final int projectedBalance;
  final Account account;

  AccountProjection({
    this.pk, 
    required this.accountPk,
    this.projectionPk,
    required this.projectedBalance,
    required this.account,
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
    Projection? projection,
    int? accountPk,
    Account? account}){
    return AccountProjection(
      pk: pk ?? this.pk,
      projectedBalance: projectedBalance ?? this.projectedBalance, 
      projectionPk: projectionPk ?? this.projectionPk, 
      accountPk: accountPk ?? this.accountPk,
      account: account ?? this.account);
  }
}

// Probably contextually wrong
Map<int?, AccountProjection?> mapAccountProjectionsByAccountPk(List<AccountProjection> accountProjections){
  Map<int?, AccountProjection?> map = { null: null };
  for (AccountProjection record in accountProjections){
    map[record.accountPk] = record;
  }
  return map;
}



// Map<int?, AccountProjection?> mapAccountProjectionsByProjectionPk(List<AccountProjection> accountProjections){
//   Map<int?, AccountProjection?> map = { null: null };
//   for (AccountProjection record in accountProjections){
//     map[record.projectionPk] = record;
//   }
//   return map;
// }


/* Implement your own unique supporting methods */
Map<int, List<AccountProjection>> mapAccountProjectionsByProjectionPk(List<AccountProjection> accountProjections){
  Map<int, List<AccountProjection>> map = { };
  for (AccountProjection row in accountProjections){
    if (map.containsKey(row.projectionPk)){
      map[row.projectionPk]!.add(row);
    }
    else{
      map[row.projectionPk!] = [row];
    }
  }
  return map;
}
