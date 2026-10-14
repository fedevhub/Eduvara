import 'package:flutter/material.dart';
import '../buttons/primary_button.dart';
import '../inputs/app_text_field.dart';
import '../../core/utils/validators.dart';

class CourseForm extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final void Function(String title, String description)? onSubmit;
  const CourseForm({
    super.key,
    this.initialTitle,
    this.initialDescription,
    this.onSubmit,
  });

  @override
  State<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<CourseForm> {
  late final title = TextEditingController(text: widget.initialTitle);
  late final description = TextEditingController(
    text: widget.initialDescription,
  );
  final keyForm = GlobalKey<FormState>();

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: keyForm,
    child: Column(
      children: [
        AppTextField(
          controller: title,
          label: 'Nama Course',
          validator: (v) => Validators.required(v, 'Nama course'),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: description,
          label: 'Deskripsi',
          validator: (v) => Validators.required(v, 'Deskripsi'),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          text: 'Simpan',
          onPressed: () {
            if (keyForm.currentState!.validate()) {
              widget.onSubmit?.call(title.text, description.text);
            }
          },
        ),
      ],
    ),
  );
}
