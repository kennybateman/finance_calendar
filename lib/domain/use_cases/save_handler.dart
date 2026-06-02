import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';


class SaveHandler{

  static Future<void> saveExcelMobile(Excel excel, String fileName) async {
    /* figure out where to save */
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.xlsx');

    /* save */
    final List<int> bytes = excel.encode()!;
    await file.writeAsBytes(bytes);

    /* offer to share */
    await SharePlus.instance.share(
      ShareParams(files: [ XFile(file.path) ]),
    );
  }

  static Future<void> saveExcelDesktop(Excel excel, String fileName) async {
    /* figure out where to save */
    final dir = await getSaveLocation(
      suggestedName: '$fileName.xlsx',
    );
    if (dir == null) return; // user might have canceled

    /* save */
    final file = File(dir.path);
    final List<int> bytes = excel.encode()!;
    await file.writeAsBytes(bytes);
  }


}