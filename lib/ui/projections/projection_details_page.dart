// Dart and Flutter
import 'package:flutter/material.dart';
// DOMAIN
import '../../domain/models/projection_read_only.dart';

class ProjectionDetailPage extends StatefulWidget {
  final ProjectionReadModel projection;
  const ProjectionDetailPage({super.key, required this.projection});

  @override
  State<ProjectionDetailPage> createState() => ProjectionDetailPageState();
}

class ProjectionDetailPageState extends State<ProjectionDetailPage> {

  @override
  Widget build(BuildContext context) {

    List<Widget> all = [
      Text(widget.projection.dateString),
      for (var balanceString in widget.projection.accountProjectionStrings()) Text(balanceString),
      for (var transactionString in widget.projection.transactionProjectionStrings()) Text(transactionString),
    ];

    return Scaffold(
      body: Padding(padding: EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: all)));
  }
}
