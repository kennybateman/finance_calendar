// Excel lib
import 'package:excel/excel.dart';
import 'dart:math';
// Data
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import '../../data/repositories/accounts_repository.dart';
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/bills_repository.dart';
// Domain 
import '../../domain/models/account.dart';
import '../../domain/models/income.dart';
import '../../domain/models/bill.dart';

/*
  PLAN: fix export so that it all works nicely.
  Problem 1: override or delete all?
    Right now just delete all. But...
    I really want to...
      1. override if they exist
      2. add if they don't
      3. don't touch if not in the backup at all

  Problem 2: how to abstract the database
    1. don't save keys, identify records by name.
    2. save linked accounts by name
    3. when importing relink the accounts

  If I do this then exporting and importing should be fairly seemless.
*/
class Backup {
  final AccountsRepository accountsRepo;
  final BillsRepository billsRepo;
  final IncomeRepository incomeRepo;
  Backup(
    this.accountsRepo, 
    this.billsRepo, 
    this.incomeRepo,
  );

  Future<Excel> backupDataToExcel() async {
    final allAccounts = await accountsRepo.getAll();
    final allBills = await billsRepo.getAll();
    final allIncome = await incomeRepo.getAll();

    final Excel excel = Excel.createExcel();

    final sheet1 = excel['accounts'];
    sheet1.appendRow([
      TextCellValue("name"),
      TextCellValue("balance"),
      TextCellValue("balance date"),
      TextCellValue("account type"),
      TextCellValue("credit limit"),
      TextCellValue("interest"),
      TextCellValue("due frequency"),
      TextCellValue("due date"),
      TextCellValue("due date anchor day"),
      TextCellValue("pay from account"),
    ]);
    for(var account in allAccounts){
      List<CellValue> cellValues = [
        TextCellValue(account.name.toString()),
        TextCellValue(account.balance.toString()),
        TextCellValue(dateToStringForDB(account.balanceDate).toString()),
        TextCellValue(account.accountType.toString()),
        TextCellValue(account.creditLimit.toString()),
        TextCellValue(account.interest.toString()),
        TextCellValue(account.dueFrequency.toString()),
        TextCellValue(dateToStringForDB(account.dueDate).toString()),
        TextCellValue(account.dueDateAnchorDay.toString()),
        TextCellValue(account.payFromAccount?.name ?? ''),
      ];
      sheet1.appendRow(cellValues);
    }

    final sheet2 = excel['income'];
    sheet2.appendRow([
      TextCellValue("name"),
      TextCellValue("amount"),
      TextCellValue("due frequency"),
      TextCellValue("due date"),
      TextCellValue("anchor day"),
      TextCellValue("pay to account"),
    ]);
    for(var income in allIncome){
      List<CellValue> cellValues = [ 
        TextCellValue(income.name.toString()),
        TextCellValue(income.amount.toString()),
        TextCellValue(income.dueFrequency.toString()),
        TextCellValue(dateToStringForDB(income.dueDate).toString()),
        TextCellValue(income.dueDateAnchorDay.toString()),
        TextCellValue(income.payToAccount?.name ?? ''),
      ];
      sheet2.appendRow(cellValues);
    }

    final sheet3 = excel['bills'];
    sheet3.appendRow([
      TextCellValue("name"),
      TextCellValue("amount"),
      TextCellValue("due frequency"),
      TextCellValue("due date"),
      TextCellValue("due date anchor day"),
      TextCellValue("pay from account"),
    ]);
    for(var bill in allBills){
      List<CellValue> cellValues = [ 
        TextCellValue(bill.name.toString()),
        TextCellValue(bill.amount.toString()),
        TextCellValue(bill.dueFrequency.toString()),
        TextCellValue(dateToStringForDB(bill.dueDate).toString()),
        TextCellValue(bill.dueDateAnchorDay.toString()),
        TextCellValue(bill.payFromAccount?.name ?? ''),
      ];
      sheet3.appendRow(cellValues);
    }

    excel.delete('Sheet1'); // remove default first sheet
    return excel;
  }

  Future<void> unpackDataFromExcel(Excel excel) async {
    final accountsRows = excel.tables['accounts']?.rows ?? [];
    List<(Account,String)> accountTuples = accountsRows.skip(1).map((row) {
      return (
        Account(
          name:               unpackString(row[0]!, randomAccountName()), // name must be unique, so I can't use a common default
          balance:            unpackInt(row[1]!),
          balanceDate:        unpackDate(row[2]!),
          accountType:        unpackString(row[3]!, 'debit'),
          creditLimit:        unpackInt(row[4]!),
          interest:           unpackInt(row[5]!),
          dueFrequency:       unpackString(row[6]!, 'monthly'),
          dueDate:            unpackDate(row[7]!),
          dueDateAnchorDay:   unpackNullableInt(row[8]!),
        ),
        unpackString(row[9]!,'')
      );
    }).toList();

    final billsRows = excel.tables['bills']?.rows ?? [];
    List<(Bill,String)> billTuples = billsRows.skip(1).map((row) {
      return (Bill(
        name:             unpackString(row[0]!, randombillName()),
        amount:           unpackInt(row[1]!),
        dueFrequency:     unpackString(row[2]!, 'monthly'),
        dueDate:          unpackDate(row[3]!),
        dueDateAnchorDay: unpackNullableInt(row[4]!),
      ),
      unpackString(row[5]!, ''));
    }).toList();

    final incomeRows = excel.tables['income']?.rows ?? [];
    List<(Income,String)> incomeTuples = incomeRows.skip(1).map((row) {
      return (
        Income(
          name:             unpackString(row[0]!, randomIncomeName()),
          amount:           unpackInt(row[1]!),
          dueFrequency:     unpackString(row[2]!, 'monthly'),
          dueDate:          unpackDate(row[3]!),
          dueDateAnchorDay: unpackNullableInt(row[4]!),
        ),
        unpackString(row[5]!, '')
      );
    }).toList();

    /* initially save all the records... */
    await accountsRepo.deleteAllAccounts();
    for(var accountTuple in accountTuples){
      await accountsRepo.createNew(accountTuple.$1);
    }
    await billsRepo.deleteAllBills();
    for(var bill in billTuples){
      await billsRepo.createNew(bill.$1);
    }
    await incomeRepo.deleteAllIncome();
    for(var income in incomeTuples){
      await incomeRepo.createNew(income.$1);
    }

    /* now load them and go over them again to link the pay accounts */
    final accountsByName = await accountsRepo.getAllByName();
    for(var accountTuple in accountTuples){
      if (accountTuple.$2 == '') continue;
      final accountName = accountTuple.$1.name;
      final accountToLinkName = accountTuple.$2;
      final account = accountsByName[accountName]!;
      final accountToLink = accountsByName[accountToLinkName];
      if (accountToLink == null) continue;
      await accountsRepo.saveChanges(account.updateValue(payFromAccountPk: accountToLink.pk));
    }

    final billsByName = await billsRepo.getAllByName();
    for(var billsTuple in billTuples){
      if (billsTuple.$2 == '') continue;
      final billName = billsTuple.$1.name;
      final accountToLinkName = billsTuple.$2;
      final bill = billsByName[billName]!;
      final accountToLink = accountsByName[accountToLinkName];
      if (accountToLink == null) continue;
      await billsRepo.saveChanges(bill.updateValue(payFromAccountPk: accountToLink.pk));
    }

    final incomeByName = await incomeRepo.getAllByName();
    for(var incomeTuple in incomeTuples){
      if (incomeTuple.$2 == '') continue;
      final incomeName = incomeTuple.$1.name;
      final accountToLinkName = incomeTuple.$2;
      final income = incomeByName[incomeName]!;
      final accountToLink = accountsByName[accountToLinkName];
      if (accountToLink == null) continue;
      await incomeRepo.saveChanges(income.updateValue(payToAccountPk: accountToLink.pk));
    }
  }



  int unpackInt(Data data){
    if (data.value is int) return data.value as int;
    return int.tryParse(data.value.toString())!;
  }

  int? unpackNullableInt(Data data){
    final val = data.toString();
     return val == "" || val == "null" ? null : int.tryParse(val);
  }

  String unpackString(Data data, String? def){
    final val = data.value.toString();
    return val == "" || val == "null" ? def! : val;
  }

  DateTime? unpackDate(Data data){
    if (data.value is DateTime) return data.value as DateTime;
    final val = data.value.toString();
    return val == "" || val == "null" ? null : stringToDate(val);
  }

  bool unpackBool(Data data){
    if (data.value is bool) return data.value as bool;
    final val = data.value.toString();
    return val == 'true';
  }

  String randomAccountName(){
    final random = Random();
    return funAccountNames[random.nextInt(funAccountNames.length)];
  }
  final funAccountNames = <String>[
    'World Domination Fund',
    'Stargate Budget',
    'Manhattan Project',
    'Deep Space Initiative',
    'Secret Volcano Base',
    'Mars Colonization Reserve',
    'Temporal Research Grant',
    'Black Ops Procurement',
    'Orbital Defense Program',
    'Interstellar Survey Fund',
    'Area 51 Maintenance',
    'Moon Base Alpha',
    'Doomsday Contingency',
    'Quantum Computing Lab',
    'Underground Bunker Expenses',
    'Antimatter Development',
    'Project Chimera',
    'Alien Diplomacy Office',
    'Cybernetic Enhancement Division',
    'Classified Acquisitions',
    'Galactic Expansion Trust',
    'Planetary Terraforming Budget',
    'Nanotech Research Fund',
    'Dragon Hoard Holdings',
    'Treasure Map Recovery',
    'Archaeological Expeditions',
    'Lost City Exploration',
    'Time Machine Repairs',
    'Parallel Universe Operations',
    'Cryptid Observation Program',
    'Monster Containment Unit',
    'Wizard Council Treasury',
    'Necromancy Endowment',
    'Artifact Recovery Team',
    'Global Surveillance Network',
    'Emergency Escape Rocket',
    'Deep Sea Exploration',
    'Robot Uprising Prevention',
    'AI Alignment Initiative',
    'Weather Control Project',
    'Subterranean Railway',
    'Phoenix Resurrection Fund',
    'Kaiju Defense Force',
    'Atlantis Infrastructure',
    'Unidentified Signal Analysis',
    'Coffee for the Resistance'
    'Villain Retirement Plan'
    'Laser Shark R&D'
    'Evil Lair Utilities'
    'Moon Rent'
    'Emergency Dinosaur Fund'
    'Hovercar Maintenance'
    'Apocalypse Preparedness'
    'Unfinished Inventions'
    'Mystery Box Purchases'
  ];

  String randomIncomeName(){
    final random = Random();
    return funIncomeNames[random.nextInt(funIncomeNames.length)];
  }
  final funIncomeNames = <String>[
    'Dragon Slaying',
    'Treasure Hunt',
    'Asteroid Dust Sales',
    'Royal Bounty',
    'Pirate Treasure Recovery',
    'Alchemy Consulting',
    'Wizard Apprenticeship Stipend',
    'Space Freight Contract',
    'Monster Extermination',
    'Artifact Discovery',
    'Time Traveler Expense Reimbursement',
    'Atlantis Salvage Rights',
    'Gold Rush Prospecting',
    'Silk Road Trading',
    'East India Cargo Dividend',
    'Privateering Commission',
    'Railroad Expansion Shares',
    'Canal Construction Bonus',
    'Frontier Homestead Grant',
    'Klondike Mining Claim',
    'Knightly Tournament Winnings',
    'Mercenary Contract',
    'Castle Siege Bonus',
    'Cartography Commission',
    'Whaling Expedition Share',
    'Treasure Island Proceeds',
    'Moby Dick Insurance Settlement',
    'Sherwood Forest Redistribution',
    'Excalibur Authentication Fees',
    'Round Table Consulting',
    'Odyssey Voyage Earnings',
    'Argonaut Expedition Dividend',
    'Trojan Horse Procurement Contract',
    'Eldorado Exploration Grant',
    'Nautilus Salvage Operations',
    'Martian Colony Payroll',
    'Terraforming Royalties',
    'Moon Mining Lease',
    'Stargate Toll Collection',
    'Robot Repair Services',
    'Artificial Intelligence Licensing',
    'Kaiju Damage Compensation',
    'Cryptid Photography Sales',
    'Parallel Universe Arbitration',
    'Interstellar Customs Refund',
  ];

  String randombillName(){
    final random = Random();
    return funBillNames[random.nextInt(funBillNames.length)];
  }
  final funBillNames = <String>[
    'Castle Mortgage',
    'Dungeon Maintenance',
    'Dragon Insurance Premium',
    'Wizard Tower Utilities',
    'Spaceship Fuel',
    'Moon Base Rent',
    'Orbital Docking Fees',
    'Stargate Access Subscription',
    'Time Machine Repairs',
    'Robot Maintenance Contract',
    'AI Cloud Hosting',
    'Evil Lair Property Tax',
    'Secret Volcano Base Utilities',
    'Castle Moat Cleaning',
    'Drawbridge Inspection',
    'Trebuchet Maintenance',
    'Royal Licensing Fees',
    'Guild Membership Dues',
    'Knight Armor Upkeep',
    'Phoenix Fire Damage Coverage',
    'Kaiju Defense Assessment',
    'Monster Containment Permit',
    'Necromancy Certification Renewal',
    'Magic Wand Replacement Plan',
    'Potion Ingredients Subscription',
    'Spellbook Publishing Fees',
    'Atlantis Flood Insurance',
    'Deep Sea Pressure Testing',
    'Submarine Hull Repairs',
    'Treasure Map Authentication',
    'Cryptid Research Grant Repayment',
    'Alien Embassy Visa Fees',
    'Terraforming Permit Costs',
    'Interstellar Customs Duty',
    'Asteroid Mining Equipment Lease',
    'Quantum Server Hosting',
    'Parallel Universe Travel Insurance',
    'Temporal Compliance Penalties',
    'Witness Protection Program',
    'Sherwood Forest Toll Charges',
    'Trojan Horse Storage Fees',
    'Nautilus Dry Dock Charges',
    'Mummy Curse Removal Service',
    'Haunted Castle Exorcism',
    'Volcano Lair HOA Dues',
  ]; 
}