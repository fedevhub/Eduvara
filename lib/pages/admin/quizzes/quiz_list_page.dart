import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/cards/quiz_card.dart';
import '../../../models/quiz_model.dart';

class AdminQuizListPage extends StatelessWidget {
  const AdminQuizListPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Daftar Quiz'),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        QuizCard(
          quiz: Quiz(id: 1, courseId: 1, title: 'Quiz Pengenalan Aljabar'),
        ),
        SizedBox(height: 10),
        QuizCard(quiz: Quiz(id: 2, courseId: 2, title: 'Quiz Eksponen')),
      ],
    ),
  );
}
