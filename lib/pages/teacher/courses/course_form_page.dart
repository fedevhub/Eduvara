import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/forms/course_form.dart';

class TeacherCourseFormPage extends StatelessWidget {
  const TeacherCourseFormPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Tambah Course', showBack: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CourseForm(onSubmit: (_, __) => Navigator.pop(context)),
    ),
  );
}
