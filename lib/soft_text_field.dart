import 'package:flutter/material.dart';

class SoftTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;

  const SoftTextField({
    required this.controller,
    required this.label,
    this.obscure = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
