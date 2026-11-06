import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/navigation/app_bar.dart';

class TeacherQuizDetailPage extends StatefulWidget {
  const TeacherQuizDetailPage({super.key});

  @override
  State<TeacherQuizDetailPage> createState() => _TeacherQuizDetailPageState();
}

class _TeacherQuizDetailPageState extends State<TeacherQuizDetailPage> {
  final _db = Supabase.instance.client;
  String? _quizId;
  Future<Map<String, dynamic>>? _quiz;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quizId != null) return;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    _quizId = arguments is Map
        ? (arguments['id'] ?? arguments['quiz_id'])?.toString()
        : arguments?.toString();
    if (_quizId != null && _quizId!.isNotEmpty) _quiz = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final quiz = Map<String, dynamic>.from(
      await _db
          .from('quizzes')
          .select(
            'id, title, description, question_count, duration_minutes, status',
          )
          .eq('id', _quizId!)
          .single(),
    );
    final questions = await _db
        .from('quiz_questions')
        .select('id, question, option_a, option_b, option_c, option_d')
        .eq('quiz_id', _quizId!)
        .order('id');
    return {...quiz, 'questions': List<Map<String, dynamic>>.from(questions)};
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Detail Quiz', showBack: true),
    body: _quiz == null
        ? const Center(child: Text('Quiz tidak ditemukan.'))
        : FutureBuilder<Map<String, dynamic>>(
            future: _quiz,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Text('Quiz belum dapat dimuat.\n${snapshot.error}'),
                );
              }
              final quiz = snapshot.data!;
              final questions = quiz['questions'] as List<Map<String, dynamic>>;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    (quiz['title'] ?? '-').toString(),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('Status: ${quiz['status'] ?? '-'}'),
                  Text('Jumlah soal: ${quiz['question_count'] ?? 0}'),
                  Text('Durasi: ${quiz['duration_minutes'] ?? 0} menit'),
                  if ((quiz['description'] ?? '').toString().isNotEmpty)
                    Text(quiz['description'].toString()),
                  const SizedBox(height: 20),
                  for (var index = 0; index < questions.length; index++)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${questions[index]['question'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            for (final option in [
                              questions[index]['option_a'],
                              questions[index]['option_b'],
                              questions[index]['option_c'],
                              questions[index]['option_d'],
                            ])
                              Text(option?.toString() ?? ''),
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
