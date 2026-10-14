import 'package:flutter/material.dart';
import '../../core/theme/input_theme.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  const AppSearchField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: AppInputTheme.decoration(
      hint: 'Cari...',
      prefixIcon: const Icon(Icons.search),
    ),
  );
}
