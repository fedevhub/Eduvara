import 'package:flutter/material.dart';
import '../../core/theme/input_theme.dart';

class AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    items: items
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(),
    onChanged: onChanged,
    decoration: AppInputTheme.decoration(label: label),
  );
}
