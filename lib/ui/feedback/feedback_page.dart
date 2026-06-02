// Dart and Flutter
import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => FeedbackPageState();
}

class FeedbackPageState extends State<FeedbackPage> {

  @override
  Widget build(BuildContext context) {

    List<Widget> all = [
      Text("Blah blah email me"),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Feedback")),
      body: Padding(padding: EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: all
      ))
    );
  }
}