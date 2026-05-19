// Data
import 'package:collection/collection.dart';
import 'package:finance_calendar/domain/models/abstract_domain_model.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';

import '../../data/repositories/projections_repository.dart';
import '../../data/repositories/accounts_repository.dart';
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/bills_repository.dart';
// Domain models
import 'package:finance_calendar/domain/models/account.dart';
import 'package:finance_calendar/domain/models/bill.dart';
import 'package:finance_calendar/domain/models/income.dart';
import 'package:finance_calendar/domain/models/projection.dart';
import 'dart:developer' as developer;

class GenerateProjectionsUseCase {
  final AccountsRepository accountsRepo;
  final BillsRepository billsRepo;
  final IncomeRepository incomeRepo;
  final ProjectionsRepository projectionsRepo;
  GenerateProjectionsUseCase(this.accountsRepo, this.billsRepo, this.incomeRepo, this.projectionsRepo);

  late List<Account> allAccounts;
  late Map<int?, Account?> accountsByPk;
  late List<Bill> allBills;
  late List<Income> allIncome;

  late DateTime earliestAccountReportDate;

  Future<void> clearProjections() async {
    await projectionsRepo.clearAllProjectionTables();
  }

  /*
    This must validate that every related record has the minimal amount of information to generate the projections.
    I currently don't allow any user created records to have incomplete information. Every created record must have
    complete information.  
  */
  void validateRecords(){
    if (allAccounts.isEmpty) throw GenerateProjectionsException("No accounts to project.");
    for(var i = 0; i < allAccounts.length; i++){
      Account account = allAccounts[i];
      if (account.balanceDate == null) throw GenerateProjectionsException("Account: ${account.name} is missing balance date.");
      if (account.accountType == 'credit'){
        if (account.accountType == 'credit' && account.dueDate == null) throw GenerateProjectionsException("Credit account: ${account.name} is missing interest due date.");
        if (account.accountType == 'credit' && account.payFromAccountPk == null) throw GenerateProjectionsException("Credit account: ${account.name} is missing interest pay from account.");
      }
    }
    for(var i = 0; i < allBills.length; i++){
      Bill bill = allBills[i];
      if (bill.dueDate == null) throw GenerateProjectionsException("Bill: ${bill.name} is missing due date.");
      if (bill.payFromAccountPk == null) throw GenerateProjectionsException("Bill: ${bill.name} is missing pay from account.");
    }
    for(var i = 0; i < allIncome.length; i++){
      Income income = allIncome[i];
      if (income.dueDate == null) throw GenerateProjectionsException("Income: ${income.name} is missing due date.");
      if (income.amount == 0) throw GenerateProjectionsException("Income: ${income.name} is missing amount.");
      if (income.payToAccountPk == null) throw GenerateProjectionsException("Income: ${income.name} is missing pay from account.");
    }
  }

  void joinRecords(){
    accountsByPk = mapByPk(allAccounts);
    for(var i = 0; i < allAccounts.length; i++){
      Account account = allAccounts[i];
      if (account.accountType == 'credit'){
        allAccounts[i] = account = account.joinPayFromAccount(accountsByPk[account.payFromAccountPk]);
      }
    }  
    for(var i = 0; i < allBills.length; i++){
      Bill bill = allBills[i];
      allBills[i] = bill.joinPayFromAccount(accountsByPk[bill.payFromAccountPk]);
    }
    for(var i = 0; i < allIncome.length; i++){
      Income income = allIncome[i];
      allIncome[i] = income.joinPayToAccount(accountsByPk[income.payToAccountPk]);
    }
  }

  /* 
    Actually, this should prevent phantom transactions, since we always catch up dueDates to the first one after
    their handling account's report date.
  */
  Future<void> catchUpDueDates() async {
    bool reloadItems = false;
    List<Account> updatedAccounts = [];
    for(var account in allAccounts){
      if (account.accountType == 'credit'){
        var dueDate = account.dueDate!;
        final balanceDate = account.payFromAccount!.balanceDate!;

        var limit = 365;
        while(dueDate.isBefore(balanceDate)){
          limit--;
          if (limit < 0) throw Exception("Credit account: ${account.name} interest dueDate too far before pay from account balance date");

          dueDate = findNextDueDate(dueDate, account.dueFrequency);
        }
        // Save the new due date to the model (not the DB)
        if (account.dueDate != dueDate){
          updatedAccounts.add(account.updateValue(dueDate: dueDate));
        }
      }
    }
    if (updatedAccounts.isNotEmpty){
      reloadItems = true;
      for(var account in updatedAccounts){
        await accountsRepo.saveChanges(account);
      }
    }

    List<Bill> updatedBills = [];
    for(var bill in allBills){
      var dueDate = bill.dueDate!;
      final balanceDate = bill.payFromAccount!.balanceDate!;

      var limit = 365;
      while(dueDate.isBefore(balanceDate)){
        limit--;
        if (limit < 0) throw Exception("Bill: ${bill.name} dueDate too far before pay from account balance date");

        dueDate = findNextDueDate(dueDate, bill.dueFrequency);
      }
      // Save the new date to the model (not the DB)
      if (bill.dueDate != dueDate){
         updatedBills.add(bill.updateValue(dueDate: dueDate));
      }
    }
    if (updatedBills.isNotEmpty){
      reloadItems = true;
      for(var bill in updatedBills){
        await billsRepo.saveChanges(bill);
      }
    }

    List<Income> updatedIncome = [];
    for(var income in allIncome){
      var dueDate = income.dueDate!;
      final balanceDate = income.payToAccount!.balanceDate!;

      var limit = 365;
      while(dueDate.isBefore(balanceDate)){
        limit--;
        if (limit < 0) throw Exception("Income: ${income.name} dueDate too far before pay to account balance date");

        dueDate = findNextDueDate(dueDate, income.dueFrequency);
      }
      // Save the new date to the model (not the DB)
      if (income.dueDate != dueDate){
        updatedIncome.add(income.updateValue(dueDate: dueDate));
      }
    }  
    if (updatedIncome.isNotEmpty){
      reloadItems = true;
      for(var income in allIncome){
        await incomeRepo.saveChanges(income);
      }
    }

    if (reloadItems){
      await loadAllItems();
    }
  }


  DateTime findNextDueDate(DateTime dueDate, String frequency){
    switch(frequency){
      case "weekly":
        return dueDate.add(Duration(days: 7));
      case "biweekly":
        return dueDate.add(Duration(days: 14));
      case "monthly":
        return DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
      default:
        throw Exception("unknown frequncy $frequency");
    }
  }

  Future<void> loadAllItems() async {
    allAccounts = await accountsRepo.getAll();
    allBills = await billsRepo.getAll();
    allIncome = await incomeRepo.getAll();
  }

  Future<void> loadAndValidateAllRecords() async {
    await loadAllItems();
    validateRecords();
  }

  Future<void> generateProjections() async {
    developer.log("wooooooh!");
    await loadAndValidateAllRecords();
    joinRecords();
    await catchUpDueDates();

    /* just before proceeding, clear the projections table */
    await clearProjections();

    /* SET UP ALGORITHM */
    /* Problem 1: different balance report dates... 
       Decision: before balance report date, account is treated as nonexistant.
       Consequence: bills or income simply will not take/give to an account before that date (potential phantom transactions)
       Also: account with earliest report date will be the projection start date.
    */
    earliestAccountReportDate = allAccounts.map((a) => a.balanceDate!).toList().sorted((a, b) => a.compareTo(b)).firstOrNull!;

    /* BEGIN ALGORITHM! ...? */
    final start = earliestAccountReportDate;
    final end = DateTime(start.year, start.month + 2, start.day);  // try 1 month of sim

    DateTime projectionDate = start;
    Projection? previousDaysProjection;
    while (projectionDate.isBefore(end)) { 
      var projectionForDay = Projection(date: projectionDate);

      for(Account account in allAccounts){
        /* initialize or carry over balance from previous day */
        final previousBalance = previousDaysProjection != null ? previousDaysProjection.accountProjectionsByAccountPk![account.pk]!.projectedBalance : account.balance;

        final isCreditAccount = account.accountType == 'credit';
        var newBalance = previousBalance;
        

        /* Make Bill Projections for interest payments */
        for(var i=0; i < allAccounts.length; i++){
          var creditAccount = allAccounts[i];
          if (creditAccount.accountType == 'credit' && creditAccount.dueDate == projectionDate && creditAccount.payFromAccountPk == account.pk){
            var billAmount = calculateCompoundInterest(previousBalance, projectionDate);
            if (isCreditAccount) {
              newBalance += billAmount;
            }
            else {
              newBalance -= billAmount;
            }

            allAccounts[i] = creditAccount.updateValue(dueDate: findNextDueDate(creditAccount.dueDate!, creditAccount.dueFrequency));

            projectionForDay.addBillProjection(BillProjection(creditAccountPk: creditAccount.pk, projectedAmount: billAmount));
          }
        }

        /* Regular bill projections */
        for(var i = 0; i < allBills.length; i++){
          Bill bill = allBills[i];
          if (bill.dueDate == projectionDate && bill.payFromAccountPk == account.pk){
            if (isCreditAccount) {
              newBalance += bill.amount;
            }
            else {
              newBalance -= bill.amount;
            }

            allBills[i] = bill.updateValue(dueDate: findNextDueDate(bill.dueDate!, bill.dueFrequency));

            projectionForDay.addBillProjection(BillProjection(billPk: bill.pk!, projectedAmount: bill.amount));
          }
        }

        /* Income projections */
        for(var i = 0; i < allIncome.length; i++){
          Income income = allIncome[i];
          if (income.dueDate == projectionDate && income.payToAccountPk == account.pk){
            if (isCreditAccount){
              newBalance -= income.amount;
            }
            else{
              newBalance += income.amount;
            }

            allIncome[i] = income.updateValue(dueDate: findNextDueDate(income.dueDate!, income.dueFrequency));

            projectionForDay.addIncomeProjection(IncomeProjection(incomePk: income.pk!, projectedAmount: income.amount));
          }
        } 

        /* After having modified the previous balance, create the projection with the result */
        projectionForDay.addAccountProjection(AccountProjection(projectedBalance: newBalance, accountPk: account.pk!));
      }

      /* remember this for tomorrow */    
      previousDaysProjection = projectionForDay;
      /* commit projection to the DB */
      await projectionsRepo.createNewReturnVoid(projectionForDay);
      /* iterate to next day */
      projectionDate = projectionDate.add(const Duration(days: 1));
    }

    developer.log("DONE RUNNING THE ALGORITHM!");
  }
}


class GenerateProjectionsException implements Exception{
  final String message;

  GenerateProjectionsException(this.message);

  @override
  String toString() => message;
}
