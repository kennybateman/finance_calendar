/* DATA LAYER */
import 'package:finance_calendar/data/repositories/accounts_repository.dart';
import 'package:finance_calendar/data/repositories/bills_repository.dart';
import 'package:finance_calendar/data/repositories/income_repository.dart';

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
import 'package:finance_calendar/domain/models/account_projection.dart';
import 'package:finance_calendar/domain/models/bill_projection.dart';
import 'package:finance_calendar/domain/models/income_projection.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

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

  ProjectionsRow domainToDataModel(Projection p){
    return ProjectionsRow(
      pk: p.pk, 
      date: dateToStringForDB(p.date)
    );
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

  Future<void> createNewReturnVoid(Projection projection) async {
    final int projectionPk = (await projectionsDao.create(domainToDataModel(projection))).pk!;

    for(var accountProjection in projection.accountProjections){
      await accountProjectionsDao.create(
        accountProjectionDomainToDataModel(
          accountProjection.updateValues(projectionPk: projectionPk)
        )
      );
    }

    for(var billProjection in projection.billProjections){
      await transactionProjectionsDao.create(
        billProjectionDomainToDataModel(
          billProjection.updateValues(projectionPk: projectionPk)
        )
      );
    }

    for(var incomeProjection in projection.incomeProjections){
      await transactionProjectionsDao.create(
        incomeProjectionDomainToDataModel(
          incomeProjection.updateValues(projectionPk: projectionPk)
        )
      );
    }
  }

  Future<Projection?> getForDate(DateTime datetime) async {
    final projectionsRow = await projectionsDao.getByDate(dateToStringForDB(datetime));
    if (projectionsRow == null) return null;
    var models = await joinSupportingRecords([projectionsRow]);
    return models.first;
  }

  Future<List<Projection>> getAllAfter(int pk) async{
    var projectionsRows = await projectionsDao.getAllAfter(pk);
    var models = await joinSupportingRecords(projectionsRows);
    return models;
  }

  @override
  Future<List<Projection>> getAll() async {
    var projectionsRows = await projectionsDao.getAll();
    var models = await joinSupportingRecords(projectionsRows);
    return models;
  }

  Future<List<Projection>> getForDateRange(DateTime start, DateTime end) async {
    var projectionsRows = await projectionsDao.getByDateRange(dateToStringForDB(start), dateToStringForDB(end));
    var models = await joinSupportingRecords(projectionsRows);
    return models;
  }

  Future<Projection?> getLast() async {
    var projectionsRow = await projectionsDao.getLast();
    if(projectionsRow == null) return null;
    var models = await joinSupportingRecords([projectionsRow]);
    return models.first;
  }

  Future<List<Projection>> joinSupportingRecords(List<ProjectionsRow> projectionsRows) async {

    /* get supporting data models */

    var projectionPks = projectionsRows.map((pr) => pr.pk!).toList();
    var accountProjectionsRows = await accountProjectionsDao.getMultipleByInt('projection_pk', projectionPks);
    var transactionProjectionsRows = await transactionProjectionsDao.getMultipleByInt('projection_pk', projectionPks);

    var accountPks = accountProjectionsRows.map((apr) => apr.account_pk).toList();
    var accountsRows = await accountsDao.getMultiple(accountPks);

    /* don't forget to check for interest payment bills where account_pk is linked instead of bill_pk */
    var billPks = transactionProjectionsRows.where((tpr) => tpr.bill_pk != null).map((tpr) => tpr.bill_pk!).toList();
    var billsRows = await billsDao.getMultiple(billPks);

    var incomePks = transactionProjectionsRows.where((tpr) => tpr.income_pk != null).map((tpr) => tpr.income_pk!).toList();
    var incomeRows = await incomeDao.getMultiple(incomePks);

    /* turn them into domain models */

    var accountsByPk = accountsRows.mapByPk();
    var billsByPK = billsRows.mapByPk();
    var incomeByPk = incomeRows.mapByPk();

    var joinedAccProjections = accountProjectionsRows
      .map((ap) => accountProjectionDataToDomainModel(ap, accountsByPk[ap.account_pk]!));

    var joinedBillProjections = transactionProjectionsRows
      .where((tpr) => tpr.bill_pk != null || tpr.account_pk != null)
      .map((bp) => billProjectionDataToDomainModel(bp, billsByPK[bp.bill_pk], accountsByPk[bp.account_pk]));

    var joinedIncomeProjections = transactionProjectionsRows
      .where((tpr) => tpr.income_pk != null)
      .map((ip) => incomeProjectionDataToDomainModel(ip, incomeByPk[ip.income_pk]!));


    var accountProjectionsByProjectionPk = mapAccountProjectionsByProjectionPk(joinedAccProjections.toList());
    var billProjectionsByProjectionPk = mapBillProjectionsByProjectionPk(joinedBillProjections.toList());
    var incomeProjectionsByProjectionPk = mapIncomeProjectionsByProjectionPk(joinedIncomeProjections.toList());

    List<Projection> fullyJoinedModels = [];
    for(ProjectionsRow projectionsRow in projectionsRows){
      fullyJoinedModels.add(
        dataToReadOnlyModel(
          projectionsRow,
          accountProjectionsByProjectionPk[projectionsRow.pk] ?? [],
          billProjectionsByProjectionPk[projectionsRow.pk] ?? [],
          incomeProjectionsByProjectionPk[projectionsRow.pk] ?? [],
        )
      );
    }
    return fullyJoinedModels.toList();
  }

  Projection dataToReadOnlyModel(ProjectionsRow pr, List<AccountProjection> aps, List<BillProjection> bps, List<IncomeProjection> ips){
    return Projection(
      pk: pr.pk!,
      date: stringToDate(pr.date)!,
      accountProjections: aps,
      billProjections: bps,
      incomeProjections: ips,
    );
  }

  AccountProjection accountProjectionDataToDomainModel(AccountProjectionsRow apr, AccountsRow ar){
    return AccountProjection(
      projectionPk: apr.projection_pk, 
      projectedBalance:  apr.projected_balance,
      accountPk: apr.account_pk, 
      account: AccountsRepository.dataToDomainModel(ar)
    );
  }

  BillProjection billProjectionDataToDomainModel(TransactionProjectionsRow apr, BillsRow? br, AccountsRow? ar){
    return BillProjection(
      projectionPk: apr.projection_pk, 
      projectedAmount:  apr.projected_amount, 
      billPk: apr.bill_pk,
      bill: br != null ? BillsRepository.dataToDomainModel(br) : null,
      creditAccountPk: apr.account_pk,
      creditAccount: ar != null ? AccountsRepository.dataToDomainModel(ar) : null,
    );
  }

  IncomeProjection incomeProjectionDataToDomainModel(TransactionProjectionsRow apr, IncomeRow ir){
    return IncomeProjection(
      projectionPk: apr.projection_pk, 
      projectedAmount:  apr.projected_amount, 
      incomePk: apr.income_pk!,
      income: IncomeRepository.dataToDomainModel(ir),
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

  @override Future<Projection> saveChanges(Projection itemWithChanges) async{
    throw Exception("Not implemented. Projection tables are immutable.");
  }

  @override Future<void> delete(Projection itemToDelete) async {
    throw Exception("Not implemented. Projection tables are immutable.");
  }
}