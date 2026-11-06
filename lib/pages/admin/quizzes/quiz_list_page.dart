import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/cards/quiz_card.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/quiz_model.dart';

class AdminQuizListPage extends StatefulWidget {
  const AdminQuizListPage({super.key});

  @override
  State<AdminQuizListPage> createState() => _AdminQuizListPageState();
}

class _AdminQuizListPageState extends State<AdminQuizListPage> {
  final _db = Supabase.instance.client;
  late Future<List<Quiz>> _quizzes;

  @override
  void initState() {
    super.initState();
    _quizzes = _load();
  }

  Future<List<Quiz>> _load() async {
    final rows = await _db
        .from('quizzes')
        .select('id, course_id, title, question_count')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows)
        .map(
          (row) => Quiz(
            id: row['id'].toString(),
            courseId: row['course_id'].toString(),
            title: (row['title'] ?? '').toString(),
            questionCount: (row['question_count'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  void _reload() => setState(() => _quizzes = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Daftar Quiz'),
    body: FutureBuilder<List<Quiz>>(
      future: _quizzes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Quiz belum dapat dimuat.\n${snapshot.error}'),
                TextButton(onPressed: _reload, child: const Text('Coba lagi')),
              ],
            ),
          );
        }

        final quizzes = snapshot.data ?? const <Quiz>[];
        if (quizzes.isEmpty) {
          return const Center(child: Text('Belum ada quiz.'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final quiz in quizzes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuizCard(
                  quiz: quiz,
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteNames.adminQuizDetail,
                    arguments: quiz.id,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
