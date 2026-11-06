import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/navigation/app_bar.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/quiz_model.dart';

class TeacherQuizListPage extends StatefulWidget {
  const TeacherQuizListPage({super.key});

  @override
  State<TeacherQuizListPage> createState() => _TeacherQuizListPageState();
}

class _TeacherQuizListPageState extends State<TeacherQuizListPage> {
  final _db = Supabase.instance.client;
  late Future<List<Quiz>> _quizzes;

  @override
  void initState() {
    super.initState();
    _quizzes = _load();
  }

  Future<List<Quiz>> _load() async {
    final teacherId = _db.auth.currentUser?.id;
    if (teacherId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final courses = await _db
        .from('courses')
        .select('id')
        .eq('teacher_id', teacherId);
    final courseIds = courses.map((row) => row['id']).toList();
    if (courseIds.isEmpty) return const [];

    final rows = await _db
        .from('quizzes')
        .select('id, course_id, title, question_count, duration_minutes')
        .inFilter('course_id', courseIds)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows)
        .map(
          (row) => Quiz(
            id: row['id'].toString(),
            courseId: row['course_id'].toString(),
            title: (row['title'] ?? '').toString(),
            questionCount: (row['question_count'] as num?)?.toInt() ?? 0,
            durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Quiz Saya'),
    body: FutureBuilder<List<Quiz>>(
      future: _quizzes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Quiz belum dapat dimuat.\n${snapshot.error}'),
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
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Ui.line),
                    boxShadow: Ui.shadow,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Ui.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${quiz.questionCount} Soal | '
                              '${quiz.durationMinutes} Menit',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Ui.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Lihat quiz',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          RouteNames.teacherQuizDetail,
                          arguments: {'id': quiz.id},
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        color: Ui.blue,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
