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
// Domain use cases
import 'due_date.dart';

import 'dart:developer' as developer;

class GenerateProjectionsUseCase {
  final AccountsRepository accountsRepo;
  final BillsRepository billsRepo;
  final IncomeRepository incomeRepo;
  final ProjectionsRepository projectionsRepo;
  final int projectionsPerGeneration;
  GenerateProjectionsUseCase(
    this.accountsRepo, 
    this.billsRepo, 
    this.incomeRepo, 
    this.projectionsRepo,
    [this.projectionsPerGeneration = 90] // optional param syntax apparently
  );

  /* 
    Always lazy load items. Don't try loading them early. Generate projections
    is meant to run after the user made some changes, usually. So if we preload models,
    we'll potentially miss those changes.
  */
  List<Account> allAccounts = [];
  List<Bill> allBills = [];
  List<Income> allIncome = [];

  Future<void> _loadAllItems() async {
    allAccounts = await accountsRepo.getAll();
    allBills = await billsRepo.getAll();
    allIncome = await incomeRepo.getAll();
  }

  late List<Account> simulatedAccounts = [];
  late List<Bill> simulatedBills = [];
  late List<Income> simulatedIncome = [];

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
  void _validateRecords(){
    // Account validation
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
    // Bill validation
    for(var i = 0; i < allBills.length; i++){
      Bill bill = allBills[i];
      if (bill.dueDate == null) throw GenerateProjectionsException("Bill: ${bill.name} is missing due date.");
      if (bill.dueDateAnchorDay == null) throw GenerateProjectionsException("Bill: ${bill.name} is missing interest due date anchor day");
      if (bill.payFromAccountPk == null) throw GenerateProjectionsException("Bill: ${bill.name} is missing pay from account.");
    }
    // Income validation
    for(var i = 0; i < allIncome.length; i++){
      Income income = allIncome[i];
      if (income.dueDate == null) throw GenerateProjectionsException("Income: ${income.name} is missing due date.");
      if (income.dueDateAnchorDay == null) throw GenerateProjectionsException("Income: ${income.name} is missing due date anchor day.");
      if (income.amount == 0) throw GenerateProjectionsException("Income: ${income.name} is missing amount.");
      if (income.payToAccountPk == null) throw GenerateProjectionsException("Income: ${income.name} is missing pay to account.");
    }
  }


  Future<void> _catchUpDueDatesToLastProjectionDate() async {
    Projection? lastProjection = await projectionsRepo.getLast();
    if (lastProjection == null) throw Exception("No last projection!");

    _clearSimulatedRecords(); // we will reload them with updated due dates
    final lastDate = lastProjection.date;
    final projectionDate = DateTime(lastDate.year, lastDate.month, lastDate.day + 1); // TRICKY! I had a bug before doing + 1
    for(var account in allAccounts){
      if (account.accountType != 'credit') continue;
      final dueDate = account.dueDate!;
      final dueDateAnchorDay = account.dueDateAnchorDay!;
      final dueFrequency = account.dueFrequency;

      final nextDueDate = DueDate.findNextDueDateAfterOrOn(projectionDate, dueDate, dueFrequency, dueDateAnchorDay);
      if (dueDate != nextDueDate){
        account = account.updateValue(dueDate: nextDueDate);
      }
      simulatedAccounts.add(account);
    }

    // Catch up bill due dates
    for(var bill in allBills){
      final dueDate = bill.dueDate!;
      final dueDateAnchorDay = bill.dueDateAnchorDay!;
      final dueFrequency = bill.dueFrequency;

      final nextDueDate = DueDate.findNextDueDateAfterOrOn(projectionDate, dueDate, dueFrequency, dueDateAnchorDay);
      if (dueDate != nextDueDate){
        bill = bill.updateValue(dueDate: nextDueDate);
      }
      simulatedBills.add(bill);
    }

    // Catch up income due dates
    for(var income in allIncome){
      final dueDate = income.dueDate!;
      final dueDateAnchorDay = income.dueDateAnchorDay!;
      final dueFrequency = income.dueFrequency;

      final nextDueDate = DueDate.findNextDueDateAfterOrOn(projectionDate, dueDate, dueFrequency, dueDateAnchorDay);
      if (dueDate != nextDueDate){
        income = income.updateValue(dueDate: nextDueDate);
      }
      simulatedIncome.add(income);
    }
    developer.log("okay...");
  }

  void _clearSimulatedRecords(){
    simulatedAccounts = [];
    simulatedBills = [];
    simulatedIncome = [];   
  }

  /* this should be the main one. and it SHOULD save the changes */
  Future<void> _catchUpDueDatesToBalanceDates() async {
    _clearSimulatedRecords();
    _loadAllItems();
    // Catch up account due dates
    for(var account in allAccounts){
      if (account.accountType == 'credit'){
        final dueDate = account.dueDate!;
        final dueDateAnchorDay = account.dueDateAnchorDay!;
        final dueFrequency = account.dueFrequency;
        final balanceDate = account.payFromAccount!.balanceDate!;

        final nextDueDate = DueDate.findNextDueDateAfterOrOn(balanceDate, dueDate, dueFrequency, dueDateAnchorDay);

        // Save the new due date to the model (not the DB)
        if (dueDate != nextDueDate){
          account = account.updateValue(dueDate: nextDueDate);
        }
      }
      simulatedAccounts.add(account);
    }

    // Catch up bill due dates
    for(var bill in allBills){
      final dueDate = bill.dueDate!;
      final dueDateAnchorDay = bill.dueDateAnchorDay!;
      final dueFrequency = bill.dueFrequency;
      final balanceDate = bill.payFromAccount!.balanceDate!;

      final nextDueDate = DueDate.findNextDueDateAfterOrOn(balanceDate, dueDate, dueFrequency, dueDateAnchorDay);

      // Save the new date to the model (not the DB)
      if (dueDate != nextDueDate){
        bill = bill.updateValue(dueDate: nextDueDate);
      }
      simulatedBills.add(bill);
    }

    // Catch up income due dates
    for(var income in allIncome){
      final dueDate = income.dueDate!;
      final dueDateAnchorDay = income.dueDateAnchorDay!;
      final dueFrequency = income.dueFrequency;
      final balanceDate = income.payToAccount!.balanceDate!;

      final nextDueDate = DueDate.findNextDueDateAfterOrOn(balanceDate, dueDate, dueFrequency, dueDateAnchorDay);

      // Save the new date to the model (not the DB)
      if (dueDate != nextDueDate){
        income = income.updateValue(dueDate: nextDueDate);
      }
      simulatedIncome.add(income);
    } 
  }



  Future<void> loadAndValidateAllRecords() async {
    await _loadAllItems();
    _validateRecords();
  }

  DateTime _getEarliestAccountReportDate(){
    return allAccounts.map((a) => a.balanceDate!).toList().sorted((date1, date2) => date1.compareTo(date2)).firstOrNull!;
  }


  Future<void> generateInitialProjections() async {
    await loadAndValidateAllRecords();

    await _catchUpDueDatesToBalanceDates();
    await clearProjections();

    await _generateProjections();
  }

  Future<void> generateMoreProjections() async { 
    await loadAndValidateAllRecords();

    await _catchUpDueDatesToLastProjectionDate();

    await _generateProjections();
  }

  /// This is the core algorithm.
  Future<void> _generateProjections() async {
    developer.log("RUNNING PROJECTIONS!");

    Projection? previousDaysProjection = await projectionsRepo.getLast();
    /* 
      Decide if we are starting from scratch (earliest account date), 
      or from a previous projection.
    */
    DateTime projectionDate;
    if (previousDaysProjection != null){
      projectionDate = DateTime(
        previousDaysProjection.date.year, 
        previousDaysProjection.date.month, 
        previousDaysProjection.date.day + 1);
    }
    else{
      projectionDate = _getEarliestAccountReportDate();
    }

    final end = DateTime(
      projectionDate.year, 
      projectionDate.month, 
      projectionDate.day + projectionsPerGeneration
    );

    /*
      For each date...
      1. Figure out which bills or income are due
      2. Figure out the daily balance after applying them
    */
    while (projectionDate.isBefore(end)) { 
      developer.log("projectionDate at beginning of loop");
      developer.log(projectionDate.toString());

      List<AccountProjection> accountProjections = [];
      List<BillProjection> billProjections = [];
      List<IncomeProjection> incomeProjections = [];

      /*
        For each account, simulate application of all bills and income...
      */
      for(Account account in allAccounts){
        final bool isCreditAccount = account.accountType == 'credit';

        final int previousBalance;
        if (previousDaysProjection != null){
          previousBalance = previousDaysProjection.accountProjectionsByAccountPk()![account.pk]!.projectedBalance;
        }
        else{
          previousBalance = account.balance;
        }


        /* This will be mutated... */
        var newBalance = previousBalance;
        
        /* Make Bill Projections for interest payments on credit accounts */
        for(int i=0; i < simulatedAccounts.length; i++){
          final Account creditAccount = simulatedAccounts[i];

          // Only credit accounts have interest payments...
          if (creditAccount.accountType == 'credit'){

            // Interest must be due _and_ for this account
            if (creditAccount.dueDate == projectionDate && creditAccount.payFromAccountPk == account.pk){
              final int billAmount = calculateCompoundInterest(previousBalance, projectionDate);
              if (isCreditAccount) {
                newBalance += billAmount;
              }
              else {
                newBalance -= billAmount;
              }

              // Use simulated accounts to track the due date
              final DateTime nextDueDate = DueDate.findNextDueDate(creditAccount.dueDate!, creditAccount.dueFrequency, creditAccount.dueDateAnchorDay!);
              simulatedAccounts[i] = creditAccount.updateValue(dueDate: nextDueDate);

              billProjections.add(BillProjection(creditAccountPk: creditAccount.pk, projectedAmount: billAmount));
            }
          }
        }

        /* Regular bill projections */
        for(int i = 0; i < simulatedBills.length; i++){
          final Bill bill = simulatedBills[i];

          if (bill.dueDate == projectionDate && bill.payFromAccountPk == account.pk){

            if (isCreditAccount) {
              newBalance += bill.amount;
            }
            else {
              newBalance -= bill.amount;
            }

            simulatedBills[i] = bill.updateValue(dueDate: DueDate.findNextDueDate(bill.dueDate!, bill.dueFrequency, bill.dueDateAnchorDay!));

            billProjections.add(BillProjection(billPk: bill.pk!, projectedAmount: bill.amount));
          }
        }

        /* Income projections */
        for(var i = 0; i < simulatedIncome.length; i++){

          final Income income = simulatedIncome[i];

          if (income.dueDate == projectionDate && income.payToAccountPk == account.pk){

            if (isCreditAccount){
              newBalance -= income.amount;
            }
            else{
              newBalance += income.amount;
            }

            simulatedIncome[i] = income.updateValue(dueDate: DueDate.findNextDueDate(income.dueDate!, income.dueFrequency, income.dueDateAnchorDay!));

            incomeProjections.add(IncomeProjection(incomePk: income.pk!, projectedAmount: income.amount));
          }
        } 

        /* Finally, create the account projection with the final balance for the day */
        accountProjections.add(AccountProjection(projectedBalance: newBalance, accountPk: account.pk!, account: account));
      }

      /* Now take all of the data for the day and create the projection model */
      final projectionForDay = Projection(
        date: projectionDate,
        accountProjections: accountProjections,
        billProjections: billProjections,
        incomeProjections: incomeProjections,
      );
      
      /* commit projection to the DB */
      developer.log("ProjectionDate at end of loop");
      developer.log(projectionDate.toString());
      await projectionsRepo.createNewReturnVoid(projectionForDay);

      /* remember this for tomorrow */    
      previousDaysProjection = projectionForDay;

      /* iterate to next day */
      projectionDate = DateTime(projectionDate.year, projectionDate.month, projectionDate.day + 1);
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
