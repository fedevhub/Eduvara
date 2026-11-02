import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

/// "Tambah Informasi Quiz" - langkah 1 sebelum menambah soal.
class TeacherQuizFormPage extends StatelessWidget {
  const TeacherQuizFormPage({super.key});

  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        const SizedBox(height: 4),
        const Text(
          'Tambah Informasi Quiz',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        FormCard(
          children: [
            const FieldLabel('Course', required: true),
            const EduSelect(
              items: [
                'Matematika Kelas 10',
                'Matematika Kelas 11',
                'Matematika Kelas 12',
              ],
            ),
            const FieldLabel('Judul Quiz', required: true),
            const EduField(),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel('Durasi', required: true),
                      EduField(keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel('Nilai Minimal', required: true),
                      EduField(keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SolidBtn(
              label: 'Selanjutnya',
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.teacherQuestionForm),
            ),
          ],
        ),
      ],
    ),
  );
}
