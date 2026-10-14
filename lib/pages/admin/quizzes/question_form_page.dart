import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/forms/question_form.dart';

class AdminQuestionFormPage extends StatelessWidget {
  const AdminQuestionFormPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Tambah Soal', showBack: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: QuestionForm(onSubmit: () => Navigator.pop(context)),
    ),
  );
}
