import 'package:flutter/material.dart';
import '../buttons/primary_button.dart';
import '../inputs/app_text_field.dart';

class QuizForm extends StatelessWidget {
  final VoidCallback? onSubmit;
  const QuizForm({super.key, this.onSubmit});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppTextField(label: 'Judul Quiz'),
      const SizedBox(height: 14),
      const AppTextField(
        label: 'Jumlah Soal',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 20),
      PrimaryButton(text: 'Simpan Quiz', onPressed: onSubmit),
    ],
  );
}
