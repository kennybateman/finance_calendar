import 'abstract_domain_model.dart';
import 'account_projection.dart';
import 'bill_projection.dart';
import 'income_projection.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

class Projection extends DomainModel<Projection> {
  @override 
  final int? pk;
  final DateTime date;
  final List<AccountProjection> accountProjections;
  final List<BillProjection> billProjections;
  final List<IncomeProjection> incomeProjections;
  Projection({
    this.pk, 
    required this.date,
    required this.accountProjections,
    required this.billProjections,
    required this.incomeProjections,
  });

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

  Map<int?, AccountProjection?>? accountProjectionsByAccountPk(){
    return mapAccountProjectionsByAccountPk(accountProjections);
  }

  @override
  String toString(){
    return "$dateString - $balancesString - $transactionsString";
  }

  /* get names of accounts or transactions */
  List<String> get accountNames => accountProjections.map((ap) => ap.account.name).toList();
  List<String> get transactionNames => 
    incomeProjections.map((ip) => ip.income!.name).toList() +
    billProjections.map((bp) => bp.creditAccount != null ? "${bp.creditAccount!.name} interest" : bp.bill!.name).toList();

  /* get amounts of accounts or transactions */
  List<int> get accountBalances => accountProjections.map((ap) => ap.projectedBalance).toList();
  List<int> get transactionAmounts => incomeProjections.map((ip) => ip.projectedAmount).toList() + billProjections.map((bp) => bp.projectedAmount).toList();

  /* get display strings for accounts or transactions */
  List<String> get accountProjectionStrings => accountProjections.map((ap) => "${ap.account.name}: \$${currencyCentsToDollarsString(ap.projectedBalance)}").toList();
  List<String> get transactionProjectionStrings => 
    incomeProjections.map((ip) => ip.toString()).toList() +
    billProjections.map((bp) => bp.toString()).toList();

  String get dateString => "${dateToStringForDisplay(date)}";
  String get balancesString => accountProjectionStrings.join(", ");
  String get transactionsString => transactionProjectionStrings.join(", ");
}

Map<String, Projection> mapReadOnlyProjectionsByDateString(List<Projection> projections){
  Map<String, Projection> map = { };
  for (Projection projection in projections){
    final dateString = dateToStringForDB(projection.date);
    map[dateString] = projection;
  }
  return map;
}
