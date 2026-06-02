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
      TextCellValue("pk"),
      TextCellValue("name"),
      TextCellValue("balance"),
      TextCellValue("balanceDate"),
      TextCellValue("accountType"),
      TextCellValue("creditLimit"),
      TextCellValue("interest"),
      TextCellValue("dueFrequency"),
      TextCellValue("dueDate"),
      TextCellValue("dueDateAnchorDay"),
      TextCellValue("payFromAccountPk"),
      TextCellValue("payFromThisAccount"),
    ]);
    for(var account in allAccounts){
      List<CellValue> cellValues = [ 
        TextCellValue(account.pk.toString()),
        TextCellValue(account.name.toString()),
        TextCellValue(account.balance.toString()),
        TextCellValue(dateToStringForDB(account.balanceDate).toString()),
        TextCellValue(account.accountType.toString()),
        TextCellValue(account.creditLimit.toString()),
        TextCellValue(account.interest.toString()),
        TextCellValue(account.dueFrequency.toString()),
        TextCellValue(dateToStringForDB(account.dueDate).toString()),
        TextCellValue(account.dueDateAnchorDay.toString()),
        TextCellValue(account.payFromAccountPk.toString()),
        TextCellValue(account.payFromThisAccount.toString()),
      ];
      sheet1.appendRow(cellValues);
    }

    final sheet2 = excel['income'];
    sheet2.appendRow([
      TextCellValue("pk"),
      TextCellValue("name"),
      TextCellValue("amount"),
      TextCellValue("dueFrequency"),
      TextCellValue("dueDate"),
      TextCellValue("dueDateAnchorDay"),
      TextCellValue("payToAccountPk"),
    ]);
    for(var income in allIncome){
      List<CellValue> cellValues = [ 
        TextCellValue(income.pk.toString()),
        TextCellValue(income.name.toString()),
        TextCellValue(income.amount.toString()),
        TextCellValue(income.dueFrequency.toString()),
        TextCellValue(dateToStringForDB(income.dueDate).toString()),
        TextCellValue(income.dueDateAnchorDay.toString()),
        TextCellValue(income.payToAccountPk.toString()),
      ];
      sheet2.appendRow(cellValues);
    }

    final sheet3 = excel['bills'];
    sheet3.appendRow([
      TextCellValue("pk"),
      TextCellValue("name"),
      TextCellValue("amount"),
      TextCellValue("dueFrequency"),
      TextCellValue("dueDate"),
      TextCellValue("dueDateAnchorDay"),
      TextCellValue("payFromAccountPk"),
    ]);
    for(var bill in allBills){
      List<CellValue> cellValues = [ 
        TextCellValue(bill.pk.toString()),
        TextCellValue(bill.name.toString()),
        TextCellValue(bill.amount.toString()),
        TextCellValue(bill.dueFrequency.toString()),
        TextCellValue(dateToStringForDB(bill.dueDate).toString()),
        TextCellValue(bill.dueDateAnchorDay.toString()),
        TextCellValue(bill.payFromAccountPk.toString()),
      ];
      sheet3.appendRow(cellValues);
    }

    excel.delete('Sheet1'); // remove default first sheet
    return excel;
  }

  Future<void> unpackDataFromExcel(Excel excel) async {
    final accountsRows = excel.tables['accounts']?.rows ?? [];
    var accounts = accountsRows.skip(1).map((row) {
      return Account(
        pk:                 unpackInt(row[0]!),
        name:               unpackString(row[1]!, randomAccountName()),
        balance:            unpackInt(row[2]!),
        balanceDate:        unpackDate(row[3]!),
        accountType:        unpackString(row[4]!, 'debit'),
        creditLimit:        unpackInt(row[5]!),
        interest:           unpackInt(row[6]!),
        dueFrequency:       unpackString(row[7]!, 'monthly'),
        dueDate:            unpackDate(row[8]!),
        dueDateAnchorDay:   unpackNullableInt(row[9]!),
        payFromAccountPk:   unpackNullableInt(row[10]!),
        payFromThisAccount: unpackBool(row[11]!),
      );
    }).toList();

    final billsRows = excel.tables['bills']?.rows ?? [];
    var bills = billsRows.skip(1).map((row) {
      return Bill(
        pk:               unpackInt(row[0]!),
        name:             unpackString(row[1]!, randombillName()),
        amount:           unpackInt(row[2]!),
        dueFrequency:     unpackString(row[3]!, 'monthly'),
        dueDate:          unpackDate(row[4]!),
        dueDateAnchorDay: unpackNullableInt(row[5]!),
        payFromAccountPk: unpackNullableInt(row[6]!),
      );
    }).toList();

    final incomeRows = excel.tables['income']?.rows ?? [];
    var incomes = incomeRows.skip(1).map((row) {
      return Income(
        pk:               unpackInt(row[0]!),
        name:             unpackString(row[1]!, randomIncomeName()),
        amount:           unpackInt(row[2]!),
        dueFrequency:     unpackString(row[3]!, 'monthly'),
        dueDate:          unpackDate(row[4]!),
        dueDateAnchorDay: unpackNullableInt(row[5]!),
        payToAccountPk:   unpackNullableInt(row[6]!),
      );
    }).toList();

    await accountsRepo.deleteAllAccounts();
    for(var account in accounts){
      await accountsRepo.createNew(account.clearPk());
    }
    await billsRepo.deleteAllBills();
    for(var bill in bills){
      await billsRepo.createNew(bill.clearPk());
    }
    await incomeRepo.deleteAllIncome();
    for(var income in incomes){
      await incomeRepo.createNew(income.clearPk());
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