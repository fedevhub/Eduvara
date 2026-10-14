import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';

class AdminMaterialDetailPage extends StatelessWidget {
  const AdminMaterialDetailPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Detail Materi', showBack: true),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengenalan Aljabar',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 14),
          Text(
            'Materi pembelajaran Eduvara menjelaskan konsep dasar secara bertahap dengan contoh yang mudah dipahami.',
            style: TextStyle(height: 1.6),
          ),
          SizedBox(height: 18),
          Text(
            'Contoh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            '2x + 3x = 5x',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}
