import 'package:flutter/material.dart';
import '../buttons/primary_button.dart';
import '../inputs/app_text_field.dart';

class MaterialForm extends StatelessWidget {
  final VoidCallback? onSubmit;
  const MaterialForm({super.key, this.onSubmit});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppTextField(label: 'Judul Materi'),
      const SizedBox(height: 14),
      const AppTextField(label: 'Isi Materi'),
      const SizedBox(height: 20),
      PrimaryButton(text: 'Simpan Materi', onPressed: onSubmit),
    ],
  );
}
