import 'package:flutter/material.dart';

class TextFormInput extends StatelessWidget{
  final String label;
  final TextEditingController controller;
  const TextFormInput(this.label, this.controller, { super.key });
  @override
  Widget build(BuildContext context){
    return TextField(decoration: InputDecoration(labelText: label), controller: controller);
  }
}
