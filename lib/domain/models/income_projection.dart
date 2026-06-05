import 'abstract_domain_model.dart';
import 'income.dart';
import 'projection.dart';

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

  @override
  String toString(){
    return "${income!.name}: \$$projectedAmount";
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

Map<int, List<IncomeProjection>> mapIncomeProjectionsByProjectionPk(List<IncomeProjection> incomeProjection){
  Map<int, List<IncomeProjection>> map = { };
  for (IncomeProjection row in incomeProjection){
    if (map.containsKey(row.projectionPk)){
      map[row.projectionPk]!.add(row);
    }
    else{
      map[row.projectionPk!] = [row];
    }
  }
  return map;
}