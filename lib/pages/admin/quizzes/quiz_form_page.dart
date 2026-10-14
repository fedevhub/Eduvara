import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/forms/quiz_form.dart';

class AdminQuizFormPage extends StatelessWidget {
  const AdminQuizFormPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Tambah Quiz', showBack: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: QuizForm(onSubmit: () => Navigator.pop(context)),
    ),
  );
}
