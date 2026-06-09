import 'dart:math';
import 'package:intl/intl.dart';


/* STRING TO TYPE AND TYPE TO STRING METHODS */

String currencyCentsToDollarsString(int? cents){
  if (cents == null) return '0.00';
  double d = cents / 100;
  return d.toStringAsFixed(2);
}

int dollarsStringToCurrencyCents(String dollarsString){
  // remove intrusive chars
  final cleaned = dollarsString.replaceAll(RegExp(r'[\$,]'), '').trim();
  final parts = cleaned.split('.');

  final dollars = int.tryParse(parts[0]) ?? 0;
  int cents = 0;
  if (parts.length > 1) {
    // make sure 0.3 reads as 30 instead of 3 by padding and truncatings to 2 chars
    final centsStr = parts[1].padRight(2, '0').substring(0, 2);
    cents = int.tryParse(centsStr) ?? 0;
  }
  return dollars * 100 + cents;
}

String dateToStringForDB(DateTime? date){
  if (date == null) return '';
  return DateFormat('yyyy-MM-dd').format(date);
}

DateTime? stringToDate(String? datestring){
  if (datestring == null || datestring == "") return null;
  try {
    return DateFormat('yyyy-MM-d').parse(datestring);
  }
  catch(_){
    return DateFormat('MM/dd/yy').parse(datestring);
  }
}

String? dateToStringForDisplay(DateTime? date){
  if (date == null) return null;
  return DateFormat('MMMM d, yyyy').format(date);
}

DateTime startOfMonth(DateTime day){
  return DateTime(day.year, day.month, 1);
}

DateTime startOfNextMonth(DateTime day){
  return DateTime(day.year, day.month+1, 1);
}

DateTime toDate(DateTime datetime){
  return DateTime(datetime.year, datetime.month, datetime.day);
}

/* FINANCIAL CALCULATIONS... */

int calculateCompoundInterest(int p, DateTime date){
  double t = percentOfYearPassed(date);
  int n = 365;
  double r = 0.36;
  return (p * (pow(1 + (r / n), n*t) - 1)).round();
}

double percentOfYearPassed(DateTime date) {
  final startOfYear = DateTime(date.year);
  final elapsed = date.difference(startOfYear).inMilliseconds;
  final total = DateTime(date.year + 1).difference(startOfYear).inMilliseconds;
  return (elapsed / total);
}
