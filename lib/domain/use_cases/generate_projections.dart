// Data
import 'package:collection/collection.dart';
import 'package:finance_calendar/domain/models/account_projection.dart';
import 'package:finance_calendar/domain/models/bill_projection.dart';
import 'package:finance_calendar/domain/models/income_projection.dart';
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
  GenerateProjectionsUseCase(
    this.accountsRepo, 
    this.billsRepo, 
    this.incomeRepo, 
    this.projectionsRepo
  );

  final int projectionsPerGeneration = 90;

  late List<Account> allAccounts;
  late Map<int?, Account?> accountsByPk;
  late List<Bill> allBills;
  late List<Income> allIncome;

  late DateTime earliestAccountReportDate;

  /*
    Once we are sure we can run the new projections algorithm, clear the old one.
    Hopefully anything that might break the algorithm will have been caught by validateRecords.
  */
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
        if (account.accountType == 'credit' && account.dueDateAnchorDay == null) throw GenerateProjectionsException("Credit account: ${account.name} is missing interest due date anchor day");
        if (account.accountType == 'credit' && account.payFromAccountPk == null) throw GenerateProjectionsException("Credit account: ${account.name} is missing interest pay from account.");
      }
    }
    for(var i = 0; i < allBills.length; i++){
      Bill bill = allBills[i];
      if (bill.dueDate == null) throw GenerateProjectionsException("Bill: ${bill.name} is missing due date.");
      if (bill.dueDateAnchorDay == null) throw GenerateProjectionsException("Bill: ${bill.name} is missing interest due date anchor day");
      if (bill.payFromAccountPk == null) throw GenerateProjectionsException("Bill: ${bill.name} is missing pay from account.");
    }
    for(var i = 0; i < allIncome.length; i++){
      Income income = allIncome[i];
      if (income.dueDate == null) throw GenerateProjectionsException("Income: ${income.name} is missing due date.");
      if (income.dueDateAnchorDay == null) throw GenerateProjectionsException("Income: ${income.name} is missing due date anchor day.");
      if (income.amount == 0) throw GenerateProjectionsException("Income: ${income.name} is missing amount.");
      if (income.payToAccountPk == null) throw GenerateProjectionsException("Income: ${income.name} is missing pay to account.");
    }
  }

  /* 
    Never change anchor day, just the dueDate.
  */
  Future<void> catchUpDueDates() async {
    bool reloadItems = false;

    List<Account> updatedAccounts = [];
    for(var account in allAccounts){
      if (account.accountType != 'credit') continue;

      var dueDate = account.dueDate!;
      var dueDateAnchorDay = account.dueDateAnchorDay!;
      final balanceDate = account.payFromAccount!.balanceDate!;

      var limit = 365;
      while(dueDate.isBefore(balanceDate)){
        limit--;
        if (limit < 0) throw Exception("Credit account: ${account.name} interest dueDate too far before pay from account balance date");

        dueDate = findNextDueDate(dueDate, account.dueFrequency, dueDateAnchorDay);
      }
      // Save the new due date to the model (not the DB)
      if (account.dueDate != dueDate){
        updatedAccounts.add(account.updateValue(dueDate: dueDate));
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
      var dueDateAnchorDay = bill.dueDateAnchorDay!;
      final balanceDate = bill.payFromAccount!.balanceDate!;

      var limit = 365;
      while(dueDate.isBefore(balanceDate)){
        limit--;
        if (limit < 0) throw Exception("Bill: ${bill.name} dueDate too far before pay from account balance date");

        dueDate = findNextDueDate(dueDate, bill.dueFrequency, dueDateAnchorDay);
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
      var dueDateAnchorDay = income.dueDateAnchorDay!;
      final balanceDate = income.payToAccount!.balanceDate!;

      var limit = 365;
      while(dueDate.isBefore(balanceDate)){
        limit--;
        if (limit < 0) throw Exception("Income: ${income.name} dueDate too far before pay to account balance date");

        dueDate = findNextDueDate(dueDate, income.dueFrequency, dueDateAnchorDay);
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

  DateTime findNextDueDate(DateTime dueDate, String frequency, int anchorDay){
    switch(frequency){
      case "weekly":
        return dueDate.add(Duration(days: 7));
      case "biweekly":
        return dueDate.add(Duration(days: 14));
      case "monthly":
        return sameDayNextMonth(dueDate, anchorDay);
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

  DateTime getEarliestAccountReportDate(){
    return allAccounts.map((a) => a.balanceDate!).toList().sorted((date1, date2) => date1.compareTo(date2)).firstOrNull!;
  }


  Future<void> generateInitialProjections() async {
    await loadAndValidateAllRecords();
    await catchUpDueDates();

    await clearProjections();

    await generateProjections();
  }

  Future<void> generateMoreProjections() async { 
    await loadAndValidateAllRecords();
    await catchUpDueDates();

    /* This needs to catch up Due Dates all the way to the last previous projection */
    /* Or this needs to be done in the core algorithm */

    await generateProjections();
  }

  /// This is the core algorithm.
  Future<void> generateProjections() async {
    developer.log("RUNNING PROJECTIONS!");

    Projection? previousDaysProjection = await projectionsRepo.getLast();
    
    // Projection date depends on whether we are running initially or subsquently
    DateTime projectionDate;
    if (previousDaysProjection != null){
      projectionDate = DateTime(
        previousDaysProjection.date.year, 
        previousDaysProjection.date.month, 
        previousDaysProjection.date.day + 1);
    }
    else{
      projectionDate = getEarliestAccountReportDate();
    }

    final end = DateTime(
      projectionDate.year, 
      projectionDate.month, 
      projectionDate.day + projectionsPerGeneration
    );

    /* These are just mutable copies that allow tracking complex due dates, like biweekly */
    List<Account> simulatedAccounts = allAccounts;
    List<Bill> simulatedBills = allBills;
    List<Income> simulatedIncome = allIncome;

    while (projectionDate.isBefore(end)) { 

      List<AccountProjection> accountProjections = [];
      List<BillProjection> billProjections = [];
      List<IncomeProjection> incomeProjections = [];

      for(Account account in allAccounts){

        int previousBalance;
        if (previousDaysProjection != null){
          previousBalance = previousDaysProjection.accountProjectionsByAccountPk()![account.pk]!.projectedBalance;
        }
        else{
          previousBalance = account.balance;
        }

        final isCreditAccount = account.accountType == 'credit';

        /* This will be mutated... */
        var newBalance = previousBalance;
        
        /* Make Bill Projections for interest payments on credit accounts */
        for(int i=0; i < simulatedAccounts.length; i++){
          Account creditAccount = simulatedAccounts[i];

          // Only credit accounts have interest payments...
          if (creditAccount.accountType != 'credit') continue;

          // Interest must be due _and_ for this account
          if (creditAccount.dueDate == projectionDate && creditAccount.payFromAccountPk == account.pk){

            final billAmount = calculateCompoundInterest(previousBalance, projectionDate);
            if (isCreditAccount) {
              newBalance += billAmount;
            }
            else {
              newBalance -= billAmount;
            }

            // Use simulated accounts to track the due date
            final nextDueDate = findNextDueDate(creditAccount.dueDate!, creditAccount.dueFrequency, creditAccount.dueDateAnchorDay!);
            simulatedAccounts[i] = creditAccount.updateValue(dueDate: nextDueDate);

            billProjections.add(BillProjection(creditAccountPk: creditAccount.pk, projectedAmount: billAmount));
          }
        }

        /* Regular bill projections */
        for(int i = 0; i < simulatedBills.length; i++){
          Bill bill = simulatedBills[i];

          if (bill.dueDate == projectionDate && bill.payFromAccountPk == account.pk){

            if (isCreditAccount) {
              newBalance += bill.amount;
            }
            else {
              newBalance -= bill.amount;
            }

            simulatedBills[i] = bill.updateValue(dueDate: findNextDueDate(bill.dueDate!, bill.dueFrequency, bill.dueDateAnchorDay!));

            billProjections.add(BillProjection(billPk: bill.pk!, projectedAmount: bill.amount));
          }
        }

        /* Income projections */
        for(var i = 0; i < simulatedIncome.length; i++){

          Income income = simulatedIncome[i];

          if (income.dueDate == projectionDate && income.payToAccountPk == account.pk){

            if (isCreditAccount){
              newBalance -= income.amount;
            }
            else{
              newBalance += income.amount;
            }

            simulatedIncome[i] = income.updateValue(dueDate: findNextDueDate(income.dueDate!, income.dueFrequency, income.dueDateAnchorDay!));

            incomeProjections.add(IncomeProjection(incomePk: income.pk!, projectedAmount: income.amount));
          }
        } 

        /* Finally, create the account projection with the final balance for the day */
        accountProjections.add(AccountProjection(projectedBalance: newBalance, accountPk: account.pk!, account: account));
      }

      /* Now take all of the data for the day and create the projection model */
      var projectionForDay = Projection(
        date: projectionDate,
        accountProjections: accountProjections,
        billProjections: billProjections,
        incomeProjections: incomeProjections,
      );
      
      /* commit projection to the DB */
      await projectionsRepo.createNewReturnVoid(projectionForDay);

      /* remember this for tomorrow */    
      previousDaysProjection = projectionForDay;

      /* iterate to next day */
      projectionDate = projectionDate.add(const Duration(days: 1));
    }
    developer.log("DONE RUNNING PROJECTIONS!");
  }
}


class GenerateProjectionsException implements Exception{
  final String message;

  GenerateProjectionsException(this.message);

  @override
  String toString() => message;
}
