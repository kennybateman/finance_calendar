import 'package:finance_calendar/domain/use_cases/helpers.dart';

import 'abstract_domain_model.dart';

/* 
  This needs to be a read only version of the Projection Model Graph.
  All information in the model graph are served up at once in whatever
  form the UI most prefers: strings. None of this should be editable
  anyway, none of this will be saved back to the DB ever.
  When saving data 
*/
class ProjectionReadModel extends DomainModel<ProjectionReadModel>{
  @override 
  final int pk;
  final DateTime date;
  final List<String> accountNames;
  final List<int> accountBalances;
  final List<String> transactionNames;
  final List<int> transactionAmounts;

  ProjectionReadModel({
    required this.pk, 
    required this.date, 
    required this.accountNames,
    required this.accountBalances,
    required this.transactionNames,
    required this.transactionAmounts,
  });

  @override
  String toString(){
    return "$dateString - $balancesString - $transactionsString";
  }

  int get numberOfAccounts => accountNames.length;

  int get numberOfTransactions => transactionNames.length;

  List<String> accountProjectionStrings(){
    List<String> accountProjectionStrings = [];
    for(int i=0; i < numberOfAccounts; i++){
      final accountName = accountNames[i];
      final balance = currencyCentsToDollarsString(accountBalances[i]);
      accountProjectionStrings.add("$accountName: \$$balance");
    }
    return accountProjectionStrings;
  }

  List<String> transactionProjectionStrings(){
    List<String> transactionProjectionStrings = [];
    for(int i=0; i < numberOfTransactions; i++){
      final name = transactionNames[i];
      final amount = currencyCentsToDollarsString(transactionAmounts[i]);
      transactionProjectionStrings.add("$name: \$$amount");
    }
    return transactionProjectionStrings;
  }

  String get dateString => "${dateToStringForDisplay(date)}";
  String get balancesString => accountProjectionStrings().join(", ");
  String get transactionsString => transactionProjectionStrings().join(", ");
  

  bool anyTransactions(){ 
    return numberOfTransactions > 0;
  }

  @override
  bool keyFieldsChanged(ProjectionReadModel other){
    throw Exception("not implemented");  
  }
}

Map<String, ProjectionReadModel> mapReadOnlyProjectionsByDateString(List<ProjectionReadModel> projections){
  Map<String, ProjectionReadModel> map = { };
  for (ProjectionReadModel projection in projections){
    final dateString = dateToStringForDB(projection.date)!;
    map[dateString] = projection;
  }
  return map;
}
