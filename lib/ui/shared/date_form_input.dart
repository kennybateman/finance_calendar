import 'package:flutter/material.dart';

class DateFormInput extends StatelessWidget{
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  const DateFormInput(this.label, this.date, this.onChanged, { super.key });

  String formatDateString(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  @override
  Widget build(BuildContext context){

    Future<void> openDatePickerAndHandleResult() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (picked != null) {
        onChanged(picked);
      }
    }

    final labelText = date == null ? "No date" : formatDateString(date!);

    return Row(children: [
      Text("$label: $labelText", style: TextStyle(fontSize: 16)),
      SizedBox(width: 8),
      ElevatedButton(onPressed: openDatePickerAndHandleResult, child: Text("Change")),
    ]);
  }
}