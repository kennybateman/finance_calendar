// Excel lib
import 'package:excel/excel.dart';
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

    final rows = excel.tables['accounts']?.rows ?? [];

    // skip header row
    final dataRows = rows.skip(1);

    var accounts = dataRows.map((row) {
      return Account(
        pk:                 unpackInt(row[0]!),
        name:               unpackString(row[1]!, ''),
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

    for(var account in accounts){
      accountsRepo.saveChanges(account);
    }

    var bills = dataRows.map((row) {
      return Bill(
        pk:               unpackInt(row[0]!),
        name:             unpackString(row[1]!, ''),
        amount:           unpackInt(row[2]!),
        dueFrequency:     unpackString(row[3]!, 'monthly'),
        dueDate:          unpackDate(row[4]!),
        dueDateAnchorDay: unpackNullableInt(row[5]!),
        payFromAccountPk: unpackNullableInt(row[6]!),
      );
    }).toList();

    for(var bill in bills){
      billsRepo.saveChanges(bill);
    }

    var incomes = dataRows.map((row) {
      return Income(
        pk:               unpackInt(row[0]!),
        name:             unpackString(row[1]!, ''),
        amount:           unpackInt(row[2]!),
        dueFrequency:     unpackString(row[3]!, 'monthly'),
        dueDate:          unpackDate(row[4]!),
        dueDateAnchorDay: unpackNullableInt(row[5]!),
        payToAccountPk:   unpackNullableInt(row[6]!),
      );
    }).toList();

    for(var income in incomes){
      incomeRepo.saveChanges(income);
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
}