/* DATA LAYER */
import '../services/database_wrapper.dart';
import '../daos/income_dao.dart';
import '../models/income_row.dart';
import 'abstract_repository.dart';
/* DOMAIN LAYER */
import 'package:finance_calendar/domain/models/income.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

class IncomeRepository extends Repository<Income>{
  late IncomeDAO dao;
  IncomeRepository(DatabaseWrapper db){
    dao = IncomeDAO(dbWrapper: db);
  }

  Income dataToDomainModel(IncomeRow row){
    return Income(
      pk: row.pk,
      name: row.name,
      amount: row.amount,
      dueFrequency: row.due_frequency,
      dueDate: stringToDate(row.due_date),
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
      pay_to_account_pk: entity.payToAccountPk,
    );
  }

  @override
  Future<Income> createNew(Income tmpItem) async {
    IncomeRow projectionRow = await dao.create(domainToDataModel(tmpItem));
    return dataToDomainModel(projectionRow);
  }

  @override
  Future<List<Income>> getAll() async { 
    var projectionRows = await dao.getAll();
    return projectionRows.map(dataToDomainModel).toList();
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
}