import 'package:flutter/material.dart';

class SelectFormInput extends StatelessWidget{
  final String label;
  final List<String> options;
  final String? selection;
  final ValueChanged<String> onChange;
  const SelectFormInput(this.label, this.options, this.selection, this.onChange, { super.key });

  @override
  Widget build(BuildContext context){
    return DropdownButtonFormField<String>(
      initialValue: selection == null || !options.contains(selection) ? options.firstOrNull : selection,
      decoration: InputDecoration(labelText: label),
      items: options.map((freq) {
        return DropdownMenuItem(
          value: freq,
          child: Text(freq),
        );
      }).toList(),
      onChanged: (selection) => onChange(selection!), // forbid null
    );
  }
}
