import 'package:flutter/material.dart';
import '../../core/theme/input_theme.dart';

class AppDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const AppDateField({
    super.key,
    required this.controller,
    this.label = 'Tanggal',
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    readOnly: true,
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDate: DateTime.now(),
      );
      if (date != null) {
        controller.text = '${date.day}/${date.month}/${date.year}';
      }
    },
    decoration: AppInputTheme.decoration(
      label: label,
      suffixIcon: const Icon(Icons.calendar_today_outlined),
    ),
  );
}
