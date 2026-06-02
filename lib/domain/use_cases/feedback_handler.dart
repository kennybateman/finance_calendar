// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import 'package:flutter/services.dart';
// UI
import 'package:url_launcher/url_launcher.dart';

class FeedbackHandler{

  static Future<void> feedbackHandlerMobile(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'ken.r.upton@gmail.com',
      query: Uri.encodeFull(
        'subject=App Feedback&body=Hi, I would like to report...\n\n',
      ),
    );

    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  }

  static Future<void> feedbackHandlerDesktop(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: 'ken.r.upton@gmail.com'),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email address copied'),
      ),
    );
  }
}