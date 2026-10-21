import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/cards/material_card.dart';
import '../../../models/materi_model.dart';

class TeacherMaterialListPage extends StatelessWidget {
  const TeacherMaterialListPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Materi'),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        MaterialCard(
          material: Materi(
            id: 1,
            courseId: 1,
            title: 'Pengenalan Aljabar',
            content: 'Konsep dan istilah dasar.',
          ),
        ),
        SizedBox(height: 8),
        MaterialCard(
          material: Materi(
            id: 2,
            courseId: 1,
            title: 'Operasi Aljabar',
            content: 'Pembahasan operasi.',
          ),
        ),
      ],
    ),
  );
}
