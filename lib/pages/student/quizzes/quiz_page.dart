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

    final quiz = Map<String, dynamic>.from(
      await _db
          .from('quizzes')
          .select(
            'id, title, description, question_count, duration_minutes, passing_score',
          )
          .eq('id', id)
          .single(),
    );

    final rows = await _db
        .from('quiz_questions')
        .select('points')
        .eq('quiz_id', id);
    final maxPoints = rows.fold<int>(
      0,
      (total, item) => total + ((item['points'] as num?)?.toInt() ?? 0),
    );
    final passingPercent = (quiz['passing_score'] as num?)?.toInt() ?? 0;
    final passingPoints = maxPoints > 0
        ? ((maxPoints * passingPercent) / 100).ceil()
        : 0;

    quiz['max_points'] = maxPoints;
    quiz['passing_points'] = passingPoints;
    return quiz;
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
      final arguments = {..._arguments, ...quiz, 'entity_name': quiz['title']};
      final quizId = quiz['id']?.toString();
      final userId = _db.auth.currentUser?.id;
      final alreadyDoneFuture = quizId != null && userId != null
          ? _db
                .from('quiz_attempts')
                .select('id, completed, score')
                .eq('user_id', userId)
                .eq('quiz_id', quizId)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle()
          : Future<Map<String, dynamic>?>.value(null);

      return FutureBuilder<Map<String, dynamic>?>(
        future: alreadyDoneFuture,
        builder: (context, doneSnapshot) {
          final alreadyDone = doneSnapshot.data?['completed'] == true;
          final latestScore = doneSnapshot.data?['score'];
          final maxPoints = (quiz['max_points'] as num?)?.toInt() ?? 0;
          final currentPercent = latestScore is num && maxPoints > 0
              ? ((latestScore.toDouble() / maxPoints) * 100).round()
              : null;
          final scoreText = latestScore is num
              ? '${latestScore.toInt()}/${maxPoints}'
              : null;
          final passLabel = currentPercent == null
              ? ((quiz['passing_score'] ?? 0).toString()) + '%'
              : currentPercent.toString() + '%';

          return EduScaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackLink(),
                Text(
                  quiz['title']?.toString() ?? 'Quiz',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _row(
                        'Jumlah Soal',
                        '${quiz['question_count'] ?? 0} Soal',
                      ),
                      _row('Durasi', '${quiz['duration_minutes'] ?? 0} Menit'),
                      _row('Nilai Lulus', passLabel),
                      _row('Skor Kamu', scoreText ?? 'Belum dikerjakan'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (!alreadyDone && (quiz['question_count'] as num? ?? 0) > 0)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteNames.studentQuestion,
                      arguments: arguments,
                    ),
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Ui.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Ui.blue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        'Mulai Quiz Sekarang',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Ui.blue,
                        ),
                      ),
                    ),
                  )
                else if ((quiz['question_count'] as num? ?? 0) <= 0)
                  Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Ui.line,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Ui.blue.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Quiz belum memiliki soal',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Ui.muted,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Ui.greenSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Ui.green.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'Sudah dikerjakan',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Ui.greenDark,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}