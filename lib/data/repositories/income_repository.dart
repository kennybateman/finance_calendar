/* DATA LAYER */
import 'package:finance_calendar/data/repositories/accounts_repository.dart';

import '../services/database_wrapper.dart';
import '../daos/income_dao.dart';
import '../daos/accounts_dao.dart';
import '../models/income_row.dart';
import 'abstract_repository.dart';
/* DOMAIN LAYER */
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';
import 'package:finance_calendar/domain/models/income.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

class IncomeRepository extends Repository<Income>{
  late IncomeDAO dao;
  late AccountsDAO accountsDao;
  IncomeRepository(DatabaseWrapper db){
    dao = IncomeDAO(dbWrapper: db);
    accountsDao = AccountsDAO(dbWrapper: db);
  }

  Income dataToDomainModel(IncomeRow row){
    return Income(
      pk: row.pk,
      name: row.name,
      amount: row.amount,
      dueFrequency: row.due_frequency,
      dueDate: stringToDate(row.due_date),
      dueDateAnchorDay: row.due_date_anchor_day,
      payToAccountPk: row.pay_to_account_pk,
    );
  }
  IncomeRow domainToDataModel(Income entity){
    return IncomeRow(
      pk: entity.pk,
      name: entity.name,
      amount: entity.amount,
      due_frequency: entity.dueFrequency,
      due_date: dateToStringForDB(entity.dueDate),
      due_date_anchor_day: entity.dueDateAnchorDay,
      pay_to_account_pk: entity.payToAccountPk,
    );
  }

  @override
  Future<Income> createNew(Income tmpItem) async {
    IncomeRow income = await dao.create(domainToDataModel(tmpItem));
    return dataToDomainModel(income);
  }

  @override
  Future<List<Income>> getAll() async { 
    var allIncomeRows = await dao.getAll();

    var allIncome = allIncomeRows.map(dataToDomainModel).toList();

    var requiredAccountPks = allIncomeRows.where((i) => i.pay_to_account_pk != null).map((i)=> i.pay_to_account_pk!).toList();
    var requiredAccountsRows = await accountsDao.getMultiple(requiredAccountPks);
    var requiredAccounts = requiredAccountsRows.map(AccountsRepository.dataToDomainModel).toList();
    var requiredAccountsByPk = mapByPk(requiredAccounts);

    List<Income> joinedIncomeModels = [];
    for(var income in allIncome){
      if (income.payToAccountPk == null){
        joinedIncomeModels.add(income);
      }
      else{
        final accountToJoin = requiredAccountsByPk[income.payToAccountPk];
        final joinedIncomeModel = income.joinPayToAccount(accountToJoin);
        joinedIncomeModels.add(joinedIncomeModel);

      }
    }
    return joinedIncomeModels;
  }

  Future<List<({int pk, String name})>> getAllNames() async { 
    final idNameTuples = await dao.getAllNames();
    return idNameTuples;
  }

  @override
  Future<Income> saveChanges(Income itemWithChanges) async{
    IncomeRow row = domainToDataModel(itemWithChanges);
    IncomeRow savedRow = await dao.update(row);
    return dataToDomainModel(savedRow);
  }

  @override
  Future<void> delete(Income itemToDelete) async {
    IncomeRow row = domainToDataModel(itemToDelete);
    dao.delete(row);
  }

  Future<void> deleteAllIncome() async {
    await dao.deleteAll();
  }
}