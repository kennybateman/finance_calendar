// Dart and Flutter
import 'package:flutter/material.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => InformationPageState();
}

class InformationPageState extends State<InformationPage> {

  @override
  Widget build(BuildContext context) {

    List<Widget> all = [
      Text("Finance Calendar by Kenny Upton 2026"),
      const SizedBox(height: 16),
      Text("Version 1.0"),
      const SizedBox(height: 16),
      Text("This app is meant to be as simple and noninvasive as possible."),
      Text("You are not required to make an account."),
      Text("You are not required to be connected to the internet."),
      Text("Data is stored locally on your phone."),
      Text("You can export/import everything."),
      Text("Until further notice this app is entirely free."),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("About")),
      body: Padding(padding: EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: all
      ))
    );
  }
}