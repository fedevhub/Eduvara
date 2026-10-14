import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/cards/quiz_card.dart';
import '../../../models/quiz_model.dart';

class AdminQuizDetailPage extends StatelessWidget {
  const AdminQuizDetailPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Detail Quiz', showBack: true),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        QuizCard(
          quiz: Quiz(
            id: 1,
            courseId: 1,
            title: 'Quiz Pengenalan Aljabar',
            questionCount: 5,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Aturan Quiz',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text(
          'Quiz hanya dapat dikerjakan satu kali. Setelah dikirim, jawaban tidak dapat diubah lagi.',
        ),
      ],
    ),
  );
}
