import 'package:finance_calendar/domain/use_cases/helpers.dart';

import 'abstract_domain_model.dart';

/* 
  This needs to be a read only version of the Projection Model Graph.
  All information in the model graph are served up at once in whatever
  form the UI most prefers: strings. None of this should be editable
  anyway, none of this will be saved back to the DB ever.
  When saving data 
*/
class ProjectionReadModel implements DomainModel{
  @override 
  final int pk;
  final DateTime date;
  
  // This needs to aggregate information form AccountProjection and Account
  // I kind of want to keep an id for each so I can at least reference it for
  // links or something. Do I really need to though? Just for accounts.
  // thus save the account id not the account projections id
  final List<(int id, String info)> accountProjectionStrings;
  final List<(int id, String type, String info)> transactionProjectionStrings;
  ProjectionReadModel({
    required this.pk, 
    required this.date, 
    required this.accountProjectionStrings,
    required this.transactionProjectionStrings,
  });

  @override
  String toString(){
    return "$dateString - $balancesString - $transactionsString";
  }

  String get dateString => "${dateToStringForDisplay(date)}";
  List<String> get balanceStrings => accountProjectionStrings.map((ap) => ap.$2).toList();
  String get balancesString => balanceStrings.join(", ");
  List<String> get transactionStrings => transactionProjectionStrings.map((ap) => ap.$3).toList();
  String get transactionsString => transactionStrings.join(", ");

  bool anyTransactions(){ 
    return transactionProjectionStrings.isNotEmpty;
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
