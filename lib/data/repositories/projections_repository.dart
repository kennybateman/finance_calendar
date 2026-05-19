/* DATA LAYER */
import '../services/database_wrapper.dart';
/* daos */
import '../daos/projections_dao.dart';
import '../daos/account_projections_dao.dart';
import '../daos/transaction_projections_dao.dart';
import '../daos/bills_dao.dart';
import '../daos/income_dao.dart';
import '../daos/accounts_dao.dart';
/* data models */
import '../models/abstract_database_row.dart';
import '../models/projections_row.dart';
import '../models/account_projections_row.dart';
import '../models/transaction_projections_row.dart';
import '../models/bills_row.dart';
import '../models/accounts_row.dart';
import '../models/income_row.dart';
/* repositories */
import 'abstract_repository.dart';
/* DOMAIN LAYER */
import 'package:finance_calendar/domain/models/projection.dart';
import 'package:finance_calendar/domain/models/projection_read_only.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

//import 'dart:developer' as developer;

class ProjectionsRepository implements Repository<Projection> {
  late ProjectionsDAO projectionsDao;
  late AccountProjectionsDAO accountProjectionsDao;
  late TransactionProjectionsDAO transactionProjectionsDao;
  late BillsDAO billsDao;
  late AccountsDAO accountsDao;
  late IncomeDAO incomeDao;

  ProjectionsRepository(DatabaseWrapper db){ 
    projectionsDao = ProjectionsDAO(dbWrapper: db);
    accountProjectionsDao = AccountProjectionsDAO(dbWrapper: db);
    transactionProjectionsDao = TransactionProjectionsDAO(dbWrapper: db);
    billsDao = BillsDAO(dbWrapper: db);
    accountsDao = AccountsDAO(dbWrapper: db);
    incomeDao = IncomeDAO(dbWrapper: db);
  }

  Projection dataToDomainModel(ProjectionsRow row){
    return Projection(pk: row.pk, date: stringToDate(row.date)!);
  }

  ProjectionsRow domainToDataModel(Projection p){
    return ProjectionsRow(pk: p.pk, date: dateToStringForDB(p.date)!);
  }

  AccountProjectionsRow accountProjectionDomainToDataModel(AccountProjection ap){
    return AccountProjectionsRow(
      pk: ap.pk, 
      projected_balance: ap.projectedBalance,
      account_pk: ap.accountPk, 
      projection_pk: ap.projectionPk! // exception if null!
    );
  }

  TransactionProjectionsRow billProjectionDomainToDataModel(BillProjection bp){
    return TransactionProjectionsRow(
      pk: bp.pk, 
      projected_amount: bp.projectedAmount,
      bill_pk: bp.billPk,
      projection_pk: bp.projectionPk!,
      account_pk: bp.creditAccountPk,
    );
  }

  TransactionProjectionsRow incomeProjectionDomainToDataModel(IncomeProjection ip){
    return TransactionProjectionsRow(
      pk: ip.pk, 
      projected_amount: ip.projectedAmount,
      income_pk: ip.incomePk,
      projection_pk: ip.projectionPk! // exception if null!
    );
  }

  /* 
    I don't want the projection database tables to be mutable at all.
    So the developer shouldn't be able to do anything to mutate Projection Models 
    after having been initially saved. Once saved,
    only the ReadOnly versions should ever be fetched from the repo.
    When needing to re-run the projection algorithm, the entire database should be cleared
    and repopulated from scratch. Don't even use delete, have the dao specify a clear table method.
  */

  Future<void> createNewReturnVoid(Projection tmpItem) async {
    /* precheck before potentially creating anything */
    if (tmpItem.pk != null) throw Exception("Projection already saved!");
    if (tmpItem.accountProjections.any((ap) => ap.pk != null)) throw Exception("Projection already saved!");
    if (tmpItem.billProjections.any((bp) => bp.pk != null)) throw Exception("Projection already saved!");
    if (tmpItem.incomeProjections.any((ip) => ip.pk != null)) throw Exception("Projection already saved!");

    ProjectionsRow projectionsRow = await projectionsDao.create(domainToDataModel(tmpItem));

    List<AccountProjectionsRow> accountProjectionsRows = [];
    for(AccountProjection accountProjection in tmpItem.accountProjections){
      /* after having saved projections, we have a pk, add that to each linked model before saving */
      AccountProjection linked = accountProjection.updateValues(projectionPk: projectionsRow.pk);
      AccountProjectionsRow accountProjectionsRow = await accountProjectionsDao.create(accountProjectionDomainToDataModel(linked));
      accountProjectionsRows.add(accountProjectionsRow);
    }

    List<TransactionProjectionsRow> transactionProjectionsRows = [];
    for(BillProjection billProjection in tmpItem.billProjections){
      BillProjection linked = billProjection.updateValues(projectionPk: projectionsRow.pk);
      TransactionProjectionsRow transactionProjectionsRow = await transactionProjectionsDao.create(billProjectionDomainToDataModel(linked));
      transactionProjectionsRows.add(transactionProjectionsRow);
    }
    for(IncomeProjection incomeProjection in tmpItem.incomeProjections){
      IncomeProjection linked = incomeProjection.updateValues(projectionPk: projectionsRow.pk);
      TransactionProjectionsRow transactionProjectionsRow = await transactionProjectionsDao.create(incomeProjectionDomainToDataModel(linked));
      transactionProjectionsRows.add(transactionProjectionsRow);
    }
  }

  Future<ProjectionReadModel?> getReadModelForDate(DateTime datetime) async {
    final projectionRow = await projectionsDao.getByDate(dateToStringForDB(datetime)!);
    if (projectionRow == null) return null;

    var accountProjectionsRows = await accountProjectionsDao.getByProjectionPk(projectionRow.pk!);
    var transactionProjectionsRows = await transactionProjectionsDao.getByProjectionPk(projectionRow.pk!);
    var accountsRows = await accountsDao.getAll();
    var billsRows = await billsDao.getAll();
    var incomeRows = await incomeDao.getAll();

    var billsByPK = billsRows.mapByPk();
    var incomeByPk = incomeRows.mapByPk();

    var accountProjectionsByProjectionPk = mapAccountProjectionsByProjectionPk(accountProjectionsRows);
    var transactionProjectionsByProjectionPk = mapTransactionProjectionsByProjectionPk(transactionProjectionsRows);

    List<AccountProjectionsRow> accountProjectionRows = accountProjectionsByProjectionPk[projectionRow.pk] ?? [];
    List<TransactionProjectionsRow> transactionProjectionRows = transactionProjectionsByProjectionPk[projectionRow.pk] ?? [];

    // Get bills for those projections
    List<BillsRow> billRows = [];
    // Get income for those projections
    List<IncomeRow> incomeRows2 = [];
    for(var row in transactionProjectionRows){
      if (row.bill_pk != null){
        billRows.add(billsByPK[row.bill_pk]!);
      }
      if (row.income_pk != null){
        incomeRows2.add(incomeByPk[row.income_pk]!);
      }
    }

    return dataToReadOnlyModel(
      projectionRow,
      accountProjectionRows,
      accountsRows,
      transactionProjectionRows,
      billRows,
      incomeRows2,
    );
  }


  Future<List<ProjectionReadModel>> getAllReadModels() async {
    var projectionsRows = await projectionsDao.getAll();
    var models = await getSupportingRecordsAndMakeDomainModel(projectionsRows);
    return models;
  }


  Future<List<ProjectionReadModel>> getSupportingRecordsAndMakeDomainModel(List<ProjectionsRow> projectionsRows) async {
    var accountProjectionsRows = await accountProjectionsDao.getAll();
    var transactionProjectionsRows = await transactionProjectionsDao.getAll();
    var accountsRows = await accountsDao.getAll();
    var billsRows = await billsDao.getAll();
    var incomeRows = await incomeDao.getAll();

    var accountProjectionsByProjectionPk = mapAccountProjectionsByProjectionPk(accountProjectionsRows);
    var transactionProjectionsByProjectionPk = mapTransactionProjectionsByProjectionPk(transactionProjectionsRows);

    // var accountsByPk = mapByPk(accountsRows);
    var billsByPK = billsRows.mapByPk();
    var incomeByPk = incomeRows.mapByPk();

    List<ProjectionReadModel> readModels = [];
    for(ProjectionsRow projectionRow in projectionsRows){

      // Get account projections for this projection
      List<AccountProjectionsRow> accountProjectionRows = accountProjectionsByProjectionPk[projectionRow.pk] ?? [];

      // Get transaction projections for this projection
      List<TransactionProjectionsRow> transactionProjectionRows = transactionProjectionsByProjectionPk[projectionRow.pk] ?? [];

      // Get bills for those projections
      List<BillsRow> billRows = [];
      // Get income for those projections
      List<IncomeRow> incomeRows = [];
      for(var row in transactionProjectionRows){
        if (row.bill_pk != null){
          billRows.add(billsByPK[row.bill_pk]!);
        }
        if (row.income_pk != null){
          incomeRows.add(incomeByPk[row.income_pk]!);
        }
      }

      // Pass precisely the relevant rows, no more or less.
      var readonlyModel = dataToReadOnlyModel(
        projectionRow,
        accountProjectionRows,
        accountsRows,
        transactionProjectionRows,
        billRows,
        incomeRows,
        );
      readModels.add(readonlyModel);
    }
    return readModels.toList();
  }


  /* I have to think about bulk operations vs singular ones. */
  Future<List<ProjectionReadModel>> getReadModelsForDateRange(DateTime start, DateTime end) async {
    var projectionsRows = await projectionsDao.getByDateRange(dateToStringForDB(start)!, dateToStringForDB(end)!);
    var models = await getSupportingRecordsAndMakeDomainModel(projectionsRows);
    return models;
  }


  ProjectionReadModel dataToReadOnlyModel(
    ProjectionsRow projectionsRow, 
    List<AccountProjectionsRow> accountProjectionsRows,
    List<AccountsRow> accountsRows,
    List<TransactionProjectionsRow> transactionProjectionsRows,
    List<BillsRow> billsRows,
    List<IncomeRow> incomeRows){

    /* get all info from accounts and their projections */
    var accountsRowsByPk = accountsRows.mapByPk();
    List<(int accountId, String projectionString)> accountProjectionStrings = [];
    for (var accountProjection in accountProjectionsRows){
      var accountsRow = accountsRowsByPk[accountProjection.account_pk];
      if (accountsRow == null) continue;

      var accountName = accountsRowsByPk[accountProjection.account_pk]!.name;
      var projectedAmount = currencyCentsToDollarsString(accountProjection.projected_balance);
      accountProjectionStrings.add((accountsRow.pk!, "$accountName: \$$projectedAmount"));
    }

    /* get all info from transactions, and their projections */
    var billsRowsByPk = billsRows.mapByPk();
    var incomeRowsByPk = incomeRows.mapByPk();
    List<(int, String, String)> transactionProjectionStrings = [];
    for (var transactionProjection in transactionProjectionsRows){
      if (transactionProjection.bill_pk != null){
        var billsRow = billsRowsByPk[transactionProjection.bill_pk];
        var billName = billsRow!.name;
        var billAmount = currencyCentsToDollarsString(transactionProjection.projected_amount);
        transactionProjectionStrings.add((billsRow.pk!, 'bill', "$billName: \$$billAmount"));
      }

      else if (transactionProjection.income_pk != null){
        var incomeRow = incomeRowsByPk[transactionProjection.income_pk];
        var incomeName = incomeRow!.name;
        var incomeAmount = currencyCentsToDollarsString(transactionProjection.projected_amount);
        transactionProjectionStrings.add((incomeRow.pk!, 'income', "$incomeName: \$$incomeAmount"));
      }
      
      else if (transactionProjection.account_pk != null){
        var creditAccount = accountsRowsByPk[transactionProjection.account_pk]!;
        var name = "${creditAccount.name} interest";
        var interestAmount = currencyCentsToDollarsString(transactionProjection.projected_amount);
        transactionProjectionStrings.add((creditAccount.pk!, 'interest', "$name: \$$interestAmount"));       
      }
    }

    return ProjectionReadModel(
      pk: projectionsRow.pk!,
      date: stringToDate(projectionsRow.date)!,
      accountProjectionStrings: accountProjectionStrings,
      transactionProjectionStrings: transactionProjectionStrings,
    );
  }

  Future<void> clearAllProjectionTables() async {
    projectionsDao.deleteAll();
    accountProjectionsDao.deleteAll();
    transactionProjectionsDao.deleteAll();
  }
  
  @override
  Future<Projection> createNew(Projection tmpItem) async {
    throw Exception("Not implemented. use createNewReturnVoid instead.");
  }

  @override Future<List<Projection>> getAll() async { 
    throw Exception("Not implemented. use getAllReadModels instead.");
  }

  @override Future<Projection> saveChanges(Projection itemWithChanges) async{
    throw Exception("Not implemented. Projection tables are immutable.");
  }

  @override Future<void> delete(Projection itemToDelete) async {
    throw Exception("Not implemented. Projection tables are immutable.");
  }
}