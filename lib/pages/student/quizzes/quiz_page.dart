import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _db = Supabase.instance.client;
  late Future<Map<String, dynamic>> _quiz;
  Map<String, dynamic> _arguments = const {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      _arguments = Map<String, dynamic>.from(arguments);
    }
    _quiz = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final id = _arguments['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Quiz tidak ditemukan. Kembali ke course.');
    }
    return Map<String, dynamic>.from(
      await _db
          .from('quizzes')
          .select(
            'id, title, description, question_count, duration_minutes, passing_score',
          )
          .eq('id', id)
          .single(),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 9))),
        Text(
          value,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _quiz,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          backgroundColor: Ui.bg,
          body: SafeArea(child: Center(child: CircularProgressIndicator())),
        );
      }
      if (snapshot.hasError || snapshot.data == null) {
        return Scaffold(
          backgroundColor: Ui.bg,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Informasi quiz belum dapat dimuat.\n${snapshot.error ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Ui.muted),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final quiz = snapshot.data!;
      final completed = quiz['completed'] == true;
      final arguments = {..._arguments, ...quiz, 'entity_name': quiz['title']};
      return EduScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            Text(
              quiz['title']?.toString() ?? 'Quiz',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if ((quiz['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                quiz['description'].toString(),
                style: const TextStyle(fontSize: 9, color: Ui.muted),
              ),
            ],
            const SizedBox(height: 10),
            EduCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Quiz',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  _row('Jumlah Soal', '${quiz['question_count'] ?? 0} Soal'),
                  _row('Durasi', '${quiz['duration_minutes'] ?? 0} Menit'),
                  _row('Nilai Lulus', '${quiz['passing_score'] ?? 0}/100'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: (quiz['question_count'] as num? ?? 0) <= 0
                  ? null
                  : () => Navigator.pushNamed(
                      context,
                      RouteNames.studentQuestion,
                      arguments: arguments,
                    ),
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (quiz['question_count'] as num? ?? 0) <= 0
                      ? Ui.line
                      : Ui.blueSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Ui.blue.withValues(alpha: 0.5)),
                ),
                child: Text(
                  (quiz['question_count'] as num? ?? 0) <= 0
                      ? 'Quiz belum memiliki soal'
                      : 'Mulai Quiz Sekarang',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: (quiz['question_count'] as num? ?? 0) <= 0
                        ? Ui.muted
                        : Ui.blue,
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
