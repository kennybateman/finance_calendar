/* DATA LAYER */
import '../services/database_wrapper.dart';
import '../daos/bills_dao.dart';
import '../models/bills_row.dart';
import 'abstract_repository.dart';
/* DOMAIN LAYER */
import 'package:finance_calendar/domain/models/bill.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

class BillsRepository extends Repository<Bill>{
  late BillsDAO dao;
  BillsRepository(DatabaseWrapper db){
    dao = BillsDAO(dbWrapper: db);
  }

  Bill dataToDomainModel(BillsRow row){
    return Bill(
      pk: row.pk,
      name: row.name,
      amount: row.amount,
      dueFrequency: row.due_frequency,
      dueDate: stringToDate(row.due_date),
      payFromAccountPk: row.pay_from_account_pk,
    );
  }
  BillsRow domainToDataModel(Bill entity){
    return BillsRow(
      pk: entity.pk,
      name: entity.name,
      amount: entity.amount,
      due_frequency: entity.dueFrequency,
      due_date: dateToStringForDB(entity.dueDate),
      pay_from_account_pk: entity.payFromAccountPk,
    );
  }

  @override
  Future<Bill> createNew(Bill tmpItem) async {
    BillsRow projectionRow = await dao.create(domainToDataModel(tmpItem));
    return dataToDomainModel(projectionRow);
  }

  @override
  Future<List<Bill>> getAll() async { 
    var projectionRows = await dao.getAll();
    return projectionRows.map(dataToDomainModel).toList();
  }

  @override
  Future<Bill> saveChanges(Bill itemWithChanges) async{
    BillsRow row = domainToDataModel(itemWithChanges);
    BillsRow savedRow = await dao.update(row);
    return dataToDomainModel(savedRow);
  }

  @override
  Future<void> delete(Bill itemToDelete) async {
    BillsRow row = domainToDataModel(itemToDelete);
    dao.delete(row);
  }
}