import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType; // ✅ keep as a field
  final Widget? prefixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hint = '',
    this.obscure = false,
    this.keyboardType = TextInputType.text, // ✅ default value (not required anymore)
    this.prefixIcon, // <- add this
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType, // ✅ now used here
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
