import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller; // Adiciona o controlador opcional
  final Icon? icon;
  final int minLines;
  final int maxLines;
  final TextInputType keyboardType; // Adiciona o keyboardType como parâmetro

  MyTextField({
    required this.label,
    this.controller, // Inicializa o controlador
    this.icon,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text, // Inicializa o keyboardType
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Usa o controlador no TextField
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType, // Aplica o keyboardType ao TextField
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: icon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
