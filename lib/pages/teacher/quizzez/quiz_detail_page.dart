import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';

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
            'id, title, description, question_count, duration_minutes, passing_score, status',
          )
          .eq('id', _quizId!)
          .single(),
    );
    final questions = await _db
        .from('quiz_questions')
        .select(
          'id, question, option_a, option_b, option_c, option_d, correct_option, points',
        )
        .eq('quiz_id', _quizId!)
        .order('id');
    return {...quiz, 'questions': List<Map<String, dynamic>>.from(questions)};
  }

  void _reload() => setState(() => _quiz = _load());

  Widget _valueField(String label, String value, {int maxLines = 1}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldLabel(label),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Ui.line),
        ),
        child: Text(
          value.isEmpty ? '-' : value,
          maxLines: maxLines,
          overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
          style: const TextStyle(fontSize: 10, color: Ui.text),
        ),
      ),
    ],
  );

  Widget _questionCard(Map<String, dynamic> question, int index) {
    final correct = (question['correct_option'] as num?)?.toInt();
    final options = [
      question['option_a'],
      question['option_b'],
      question['option_c'],
      question['option_d'],
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormCard(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Ui.blue,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question['question']?.toString().trim().isNotEmpty == true
                      ? question['question'].toString()
                      : 'Pertanyaan belum diisi',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var optionIndex = 0; optionIndex < options.length; optionIndex++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: optionIndex == correct ? Ui.blueTint : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: optionIndex == correct ? Ui.blue : Ui.line,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + optionIndex),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: optionIndex == correct ? Ui.blue : Ui.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        options[optionIndex]?.toString().trim().isNotEmpty ==
                                true
                            ? options[optionIndex].toString()
                            : '-',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    if (optionIndex == correct)
                      const Icon(Icons.check_circle, color: Ui.blue, size: 15),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              const Text('Nilai', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 8),
              Text(
                '${question['points'] ?? 0} poin',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        const SizedBox(height: 4),
        const Text(
          'Detail Quiz',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (_quiz == null)
          const Center(child: Text('Quiz tidak ditemukan.'))
        else
          FutureBuilder<Map<String, dynamic>>(
            future: _quiz,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Column(
                    children: [
                      Text(
                        'Quiz belum dapat dimuat.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!;
              final questions = data['questions'] as List<Map<String, dynamic>>;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormCard(
                    children: [
                      _valueField('Judul Quiz', '${data['title'] ?? '-'}'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _valueField(
                              'Durasi (menit)',
                              '${data['duration_minutes'] ?? 0}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _valueField(
                              'Nilai Minimal',
                              '${data['passing_score'] ?? 0}',
                            ),
                          ),
                        ],
                      ),
                      _valueField('Jumlah Soal', '${questions.length} soal'),
                      _valueField(
                        'Deskripsi',
                        '${data['description'] ?? ''}',
                        maxLines: 3,
                      ),
                      FieldLabel('Status'),
                      Pill(
                        '${data['status'] ?? '-'}',
                        kind: data['status'] == 'published'
                            ? PillKind.active
                            : PillKind.inactive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daftar Soal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (questions.isEmpty)
                    const Text(
                      'Quiz ini belum memiliki soal.',
                      style: TextStyle(fontSize: 10, color: Ui.muted),
                    )
                  else
                    for (var index = 0; index < questions.length; index++)
                      _questionCard(questions[index], index),
                ],
              );
            },
          ),
      ],
    ),
  );
}
