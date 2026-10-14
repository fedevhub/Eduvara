import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/course/course_header.dart';
import '../../../components/course/course_info.dart';
import '../../../components/course/course_material_list.dart';
import '../../../models/course_model.dart';
import '../../../models/materi_model.dart';

class AdminCourseDetailPage extends StatelessWidget {
  const AdminCourseDetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    const course = Course(
      id: 1,
      title: 'Pengenalan Aljabar',
      description: 'Konsep dasar aljabar dan bentuk aljabar.',
      teacher: 'Bu Eduvara',
    );
    const materials = [
      Materi(
        id: 1,
        courseId: 1,
        title: 'Pengenalan Aljabar',
        content: 'Konsep dan istilah dasar.',
      ),
      Materi(
        id: 2,
        courseId: 1,
        title: 'Operasi Aljabar',
        content: 'Penjumlahan dan pengurangan bentuk aljabar.',
      ),
    ];
    return Scaffold(
      appBar: const EduvaraAppBar(title: 'Detail Course', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CourseHeader(course: course),
          const SizedBox(height: 18),
          const CourseInfo(course: course),
          const SizedBox(height: 22),
          const Text(
            'Materi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          CourseMaterialList(materials: materials, onTap: (_) {}),
        ],
      ),
    );
  }
}
