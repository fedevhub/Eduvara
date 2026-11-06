import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/cards/quiz_card.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../models/quiz_model.dart';

class AdminQuizDetailPage extends StatefulWidget {
  const AdminQuizDetailPage({super.key});

  @override
  State<AdminQuizDetailPage> createState() => _AdminQuizDetailPageState();
}

class _AdminQuizDetailPageState extends State<AdminQuizDetailPage> {
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
            'id, course_id, title, description, question_count, duration_minutes, passing_score, status',
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

  void _reload() => setState(() => _quiz = _load());

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Quiz belum dapat dimuat.\n${snapshot.error}'),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!;
              final quiz = Quiz(
                id: data['id'].toString(),
                courseId: data['course_id'].toString(),
                title: (data['title'] ?? '').toString(),
                questionCount: (data['question_count'] as num?)?.toInt() ?? 0,
              );
              final questions = data['questions'] as List<Map<String, dynamic>>;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  QuizCard(quiz: quiz),
                  const SizedBox(height: 12),
                  Text('Status: ${data['status'] ?? '-'}'),
                  Text('Durasi: ${data['duration_minutes'] ?? 0} menit'),
                  Text('Nilai lulus: ${data['passing_score'] ?? 0}/100'),
                  if ((data['description'] ?? '').toString().isNotEmpty)
                    Text(data['description'].toString()),
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Soal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (questions.isEmpty)
                    const Text('Quiz ini belum memiliki soal.')
                  else
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
