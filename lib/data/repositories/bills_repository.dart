/* DATA LAYER */
import '../services/database_wrapper.dart';
import '../daos/bills_dao.dart';
import '../daos/accounts_dao.dart';
import '../models/bills_row.dart';
import 'abstract_repository.dart';
import 'accounts_repository.dart';
/* DOMAIN LAYER */
import 'package:finance_calendar/domain/models/bill.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';

class BillsRepository extends Repository<Bill>{
  late BillsDAO dao;
  late AccountsDAO accountsDao;
  BillsRepository(DatabaseWrapper db){
    dao = BillsDAO(dbWrapper: db);
    accountsDao = AccountsDAO(dbWrapper: db);
  }

  Bill dataToDomainModel(BillsRow row){
    return Bill(
      pk: row.pk,
      name: row.name,
      amount: row.amount,
      dueFrequency: row.due_frequency,
      dueDate: stringToDate(row.due_date),
      dueDateAnchorDay: row.due_date_anchor_day,
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
      due_date_anchor_day: entity.dueDateAnchorDay,
      pay_from_account_pk: entity.payFromAccountPk,
    );
  }

  @override
  Future<Bill> createNew(Bill tmpItem) async {
    BillsRow billsRow = await dao.create(domainToDataModel(tmpItem));
    return dataToDomainModel(billsRow);
  }

  @override
  Future<List<Bill>> getAll() async { 
    var allBillsRows = await dao.getAll();
    final allBills = allBillsRows.map(dataToDomainModel).toList();

    var requiredAccountPks = allBillsRows.where((b) => b.pay_from_account_pk != null).map((b)=> b.pay_from_account_pk!).toList();
    var requiredAccountsRows = await accountsDao.getMultiple(requiredAccountPks);
    var requiredAccounts = requiredAccountsRows.map(AccountsRepository.dataToDomainModel).toList();
    var requiredAccountsByPk = mapByPk(requiredAccounts);

    List<Bill> joinedBillModels = [];
    for(var bill in allBills){
      if (bill.payFromAccountPk == null){
        joinedBillModels.add(bill);
      }
      else{
        final accountToJoin = requiredAccountsByPk[bill.payFromAccountPk];
        final joinedBillModel = bill.joinPayFromAccount(accountToJoin);
        joinedBillModels.add(joinedBillModel);
      }
    }
    return joinedBillModels;
  }

  Future<Map<String?, Bill?>> getAllByName() async {
    final allBills = await getAll();

    Map<String?, Bill?>  map = { null: null };
    for (Bill bill in allBills){
      map[bill.name] = bill;
    }
    return map;
  }

  Future<List<(int, String)>> getAllNames() async { 
    final idNameTuples = await dao.getAllNames();
    return idNameTuples;
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

  Future<void> deleteAllBills() async {
    await dao.deleteAll();
  }
}