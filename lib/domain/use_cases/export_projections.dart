// Excel lib
import 'package:excel/excel.dart';
import 'package:collection/collection.dart';
// Data
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import '../../data/repositories/projections_repository.dart';

class ExportProjections {
  final ProjectionsRepository projectionsRepo;
  ExportProjections(
    this.projectionsRepo,
  );

  Future<Excel> backupDataToExcel() async {
    var projections = await projectionsRepo.getAll();
    var accountNames = projections.first.accountNames;

    final Excel excel = Excel.createExcel();
    final sheet1 = excel['projections'];
    /* Set up the headers */
    sheet1.appendRow([
      TextCellValue("date"),
      for(var accountName in accountNames) TextCellValue(accountName),
      TextCellValue("transaction total"),
      TextCellValue("transactions"),
    ]);
    /* Each projection is a spreadsheet row */
    for(var projection in projections){
      List<CellValue> cellValues = [ 
        TextCellValue(dateToStringForDisplay(projection.date)!),
        for(var accountBalance in projection.accountBalances) TextCellValue(currencyCentsToDollarsString(accountBalance)),
        TextCellValue(currencyCentsToDollarsString(projection.transactionAmounts.sum)),
        TextCellValue(projection.transactionsString),
      ];
      sheet1.appendRow(cellValues);
    }

    excel.delete('Sheet1'); // remove default first sheet
    return excel;
  }
}