// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/settings_repository.dart';
// DOMAIN
import '../../domain/models/projection_read_only.dart';
import '../../domain/models/settings.dart';

class ProjectionDetailPage extends StatefulWidget {
  final ProjectionReadModel projection;
  final SettingsRepository settingsRepo;
  const ProjectionDetailPage({
    super.key, 
    required this.projection,
    required this.settingsRepo,
  });

  @override
  State<ProjectionDetailPage> createState() => ProjectionDetailPageState();
}

class ProjectionDetailPageState extends State<ProjectionDetailPage> {
    /* zoom variables */
  late double startScale = widget.settingsRepo.getSettings().fontSize;
  late double scale = startScale;

  @override
  Widget build(BuildContext context) {

    final appBar = AppBar(
      actions: [
        IconButton(
          icon: Icon(Icons.remove),
          tooltip: "Zoom out",
          onPressed: () async {
            var settings = widget.settingsRepo.getSettings();
            setState(() {
              scale = (settings.fontSize - 0.1).clamp(0.4, 1.0);
            });
            widget.settingsRepo.updateSettings(Settings(darkMode: settings.darkMode, fontSize: scale));
          },
        ),
        IconButton(
          icon: Icon(Icons.add),
          tooltip: "Zoom in",
          onPressed: () {
            var settings = widget.settingsRepo.getSettings();
            setState(() {
              scale = (settings.fontSize + 0.1).clamp(0.4, 1.0);
            });
            widget.settingsRepo.updateSettings(Settings(darkMode: settings.darkMode, fontSize: scale));
          },
        ),
      ]
    );


    List<Widget> all = [
      Text(widget.projection.dateString, style: TextStyle(fontSize: 16 * scale)),
      for (var balanceString in widget.projection.accountProjectionStrings()) Text(balanceString, style: TextStyle(fontSize: 16 * scale)),
      for (var transactionString in widget.projection.transactionProjectionStrings()) Text(transactionString, style: TextStyle(fontSize: 16 * scale)),
    ];

    return Scaffold(
      appBar: appBar,
      body: Padding(padding: EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: all)));
  }
}
