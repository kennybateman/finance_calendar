/* DATA LAYER */
import '../services/database_wrapper.dart';
import '../daos/accounts_dao.dart';
import '../models/accounts_row.dart';
import 'abstract_repository.dart';
/* DOMAIN LAYER */
import 'package:finance_calendar/domain/models/account.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';

import 'dart:developer' as dev;

class AccountsRepository implements Repository<Account>{
  late AccountsDAO dao;
  AccountsRepository(DatabaseWrapper db){
    dao = AccountsDAO(dbWrapper: db);
  }

  static Account dataToDomainModel(AccountsRow row){
    return Account(
      pk: row.pk,
      name: row.name,
      balance: row.balance,
      balanceDate: stringToDate(row.balance_date),
      accountType: row.account_type,
      creditLimit: row.credit_limit ?? 0,
      interest: row.interest ?? 0,
      dueFrequency: row.due_frequency ?? 'monthly',
      dueDate: stringToDate(row.due_date),
      dueDateAnchorDay: row.due_date_anchor_day,
      payFromAccountPk: row.pay_from_account_pk,
    );
  }

  AccountsRow domainToDataModel(Account entity){
    return AccountsRow(
      pk: entity.pk,
      name: entity.name,
      balance: entity.balance,
      balance_date: dateToStringForDB(entity.balanceDate),
      account_type: entity.accountType,
      credit_limit: entity.creditLimit,
      interest: entity.interest,
      due_frequency: entity.dueFrequency,
      due_date: dateToStringForDB(entity.dueDate),
      due_date_anchor_day: entity.dueDateAnchorDay,
      pay_from_account_pk: entity.payFromAccountPk,
    );
  }

  @override
  Future<Account> createNew(Account tmpItem) async {
    /* 
      New accounts have a special condition where they need to be saved
      to get a pk in order to set that pk for the payFromAccountPk, for cases
      where a credit card pays its own interest.
    */
    final bool payFromThisAccount = tmpItem.payFromThisAccount;
    dev.log("OKAY PEEKING");
    dev.log(payFromThisAccount.toString());
    AccountsRow accountsRow = await dao.create(domainToDataModel(tmpItem));
    /* If payFromThisAccount, then take that pk save the record with it as the pay from account */
    if (payFromThisAccount){
      accountsRow = await dao.update(accountsRow.updateValue(pay_from_account_pk: accountsRow.pk));
    }
    return dataToDomainModel(accountsRow);
  }

  @override
  Future<List<Account>> getAll() async { 
    final allAccountRows = await dao.getAll();
    final allAccounts = allAccountRows.map(dataToDomainModel).toList();
    final allAccountsByPk = mapByPk(allAccounts);

    List<Account> joinedAccountModels = [];
    for(var account in allAccounts){
      if (account.accountType != 'credit' || account.payFromAccountPk == null){
        joinedAccountModels.add(account);
      }
      else{
        final accountToJoin = allAccountsByPk[account.payFromAccountPk];
        final joinedAccountModel = account.joinPayFromAccount(accountToJoin);
        joinedAccountModels.add(joinedAccountModel);
      }
    }
    return joinedAccountModels;
  }

  Future<Map<String?, Account?>> getAllByName() async {
    final allAccounts = await getAll();

    Map<String?, Account?>  map = { null: null };
    for (Account account in allAccounts){
      map[account.name] = account;
    }
    return map;
  }

  Future<List<({int pk, String name})>> getAllNames() async { 
    final idNameTuples = await dao.getAllNames();
    return idNameTuples;
  }

  @override
  Future<Account> saveChanges(Account itemWithChanges) async{
    AccountsRow row = domainToDataModel(itemWithChanges);
    AccountsRow savedRow = await dao.update(row);
    return dataToDomainModel(savedRow);
  }

  @override
  Future<void> delete(Account itemToDelete) async {
    AccountsRow row = domainToDataModel(itemToDelete);
    await dao.delete(row);
  }

  Future<void> deleteAllAccounts() async {
    await dao.deleteAll();
  }
}