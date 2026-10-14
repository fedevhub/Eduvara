import 'package:flutter/material.dart';
import '../buttons/primary_button.dart';
import '../inputs/app_text_field.dart';

class QuestionForm extends StatelessWidget {
  final VoidCallback? onSubmit;
  const QuestionForm({super.key, this.onSubmit});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppTextField(label: 'Pertanyaan'),
      const SizedBox(height: 12),
      const AppTextField(label: 'Pilihan A'),
      const SizedBox(height: 12),
      const AppTextField(label: 'Pilihan B'),
      const SizedBox(height: 12),
      const AppTextField(label: 'Pilihan C'),
      const SizedBox(height: 12),
      const AppTextField(label: 'Pilihan D'),
      const SizedBox(height: 20),
      PrimaryButton(text: 'Simpan Soal', onPressed: onSubmit),
    ],
  );
}
