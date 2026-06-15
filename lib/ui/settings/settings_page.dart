// Dart and Flutter
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:excel/excel.dart';
// DOMAIN
import '../../domain/models/settings.dart';
import '../../domain/use_cases/generate_projections.dart';
// UI
import '../shared/switch_form_input.dart';
import '../information/information_page.dart';
// DEBUG
import 'dart:developer' as dev;

class SettingsPage extends StatefulWidget {
  final Settings Function() getSettings;
  final void Function(Settings) saveSettings;
  final InformationPage informationPage;
  final Future<void> Function(Excel, String) saveHandler;
  final Future<void> Function(BuildContext) feedbackHandler;
  final Future<Excel> Function() backupDataToExcel;
  final Future<void> Function(Excel) unpackDataFromExcel;
  final Future<Excel> Function() exportProjectionToExcel;
  final Future<void> Function() checkIfExcelCanExport;
  final Future<void> Function() generateProjections;
  final Future<void> Function() clearProjections;
  const SettingsPage({
    super.key,
    required this.getSettings,
    required this.saveSettings,
    required this.informationPage,
    required this.saveHandler,
    required this.feedbackHandler,
    required this.backupDataToExcel,
    required this.unpackDataFromExcel,
    required this.exportProjectionToExcel,
    required this.checkIfExcelCanExport,
    required this.generateProjections,
    required this.clearProjections,
  });

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  String message = '';
  bool loading = false;

  void darkModeOnChange(bool value) async {
    final existingSettings = widget.getSettings();
    widget.saveSettings(Settings(darkMode: value, fontSize: existingSettings.fontSize));
    setState((){});
  }

  Future<void> openAboutPage() async {
    await Navigator.push(context,
      MaterialPageRoute(builder: (_) => InformationPage()),
    );
  }

  Future<void> exportButtonClick() async {
    try{
      
      await widget.checkIfExcelCanExport();

      final Excel excel = await widget.exportProjectionToExcel();

      await widget.saveHandler(excel, "finance_calendar_projections");

    } on Exception catch(ex){
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ex.toString()),
        ),
      );
    }
  }

  Future<void> backupButtonClick() async {
    final excel = await widget.backupDataToExcel();
    await widget.saveHandler(excel, "finance_calendar_backup");
  }

  Future<void> importBackupButtonClick() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Excel',
          extensions: ['xlsx'],
        ),
      ],
    );

    if (file == null) return;

    /*
      When importing, things can go wrong.
      If they do, report the error, and clear projections.
    */
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      await widget.unpackDataFromExcel(excel);

    } on Exception catch(ex){
      /*
        If anything went wrong, then report it
        as an app bar message. And clear projections.
      */
      if (mounted){
        setState((){
          message = ex.toString();
        });

        await widget.clearProjections();
      }
      return;
    }

    if (mounted){
      setState((){
        loading = true;
      });
    }

    try{
      /*
        If no errors occured, try to run projections.
      */
      await widget.generateProjections();

    } on GenerateProjectionsException catch(ex){
      /*
        If can't generate projections, report the error.
      */
      if (mounted){
        setState((){
          message = ex.toString();
          loading = false;
        });
      }
    }

    if (mounted){
      setState((){
        loading = false;
      });
    }
  }

  Future<void> feedbackButtonClick() async {
    await widget.feedbackHandler(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.getSettings();

    List<Widget> all = [
      SwitchFormInput(
        label: "Dark mode", 
        value: settings.darkMode, 
        onChange: darkModeOnChange,
      ),
      TextButton(
        onPressed: exportButtonClick,
        child: const Text("Export"),
      ),
      TextButton(
        onPressed: backupButtonClick,
        child: const Text("Backup"),
      ),
      TextButton(
        onPressed: importBackupButtonClick,
        child: const Text("Import backup"),
      ),
      TextButton(
        onPressed: feedbackButtonClick,
        child: const Text("Feedback"),
      ),
      TextButton(
        onPressed: openAboutPage,
        child: const Text("About"),
      ),
    ];

    final appMessage = Text(
      message, 
      style: TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold
      )
    );

    final alignmentStructure = Padding(
      padding: EdgeInsets.all(16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: all
      )
    );

    final circleWaiting = const Center(child: CircularProgressIndicator());
    final indexedStack = IndexedStack(index: loading ? 0 : 1, children: [ circleWaiting, alignmentStructure ]);

    return Scaffold(
      appBar: AppBar(title: appMessage),
      body: indexedStack
    );
  }
}