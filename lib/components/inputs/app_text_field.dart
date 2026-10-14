import 'package:flutter/material.dart';
import '../../core/theme/input_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    validator: validator,
    keyboardType: keyboardType,
    decoration: AppInputTheme.decoration(
      label: label,
      hint: hint,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
    ),
  );
}
