import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class _ResultData {
  final int score;
  final int correct;
  final int wrong;
  final int passingScore;
  final dynamic courseId;
  const _ResultData(
    this.score,
    this.correct,
    this.wrong,
    this.passingScore,
    this.courseId,
  );

  bool get passed => score >= passingScore;
}

class QuizResultPage extends StatefulWidget {
  const QuizResultPage({super.key});

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  final _db = Supabase.instance.client;

  Future<_ResultData>? _result;
  String? _attemptId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _attemptId = args['attempt_id']?.toString();
    } else if (args is String && args.isNotEmpty) {
      _attemptId = args;
    }
    if (_attemptId != null) _result = _load();
  }

  Future<_ResultData> _load() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw 'Sesi login berakhir, silakan login ulang';

    try {
      final row = await _db
          .from('quiz_attempts')
          .select(
            'score, correct_count, wrong_count, quizzes(course_id, passing_score)',
          )
          .eq('id', _attemptId!)
          .eq('user_id', uid)
          .single();

      final quiz = row['quizzes'] as Map?;
      return _ResultData(
        (row['score'] as num?)?.round() ?? 0,
        (row['correct_count'] as num?)?.toInt() ?? 0,
        (row['wrong_count'] as num?)?.toInt() ?? 0,
        (quiz?['passing_score'] as num?)?.toInt() ?? 80,
        quiz?['course_id'],
      );
    } on PostgrestException catch (e) {
      if (!_isMissingTableError(e)) rethrow;
      return const _ResultData(0, 0, 0, 80, null);
    }
  }

  void _reload() {
    final next = _load();
    if (!mounted) return;
    setState(() {
      _result = next;
    });
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontSize: 9))),
        Text(
          v,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _content(_ResultData d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        color: Ui.blue,
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 36,
          20,
          28,
        ),
        child: Column(
          children: [
            Text(
              d.passed ? 'Anda Lulus' : 'Anda Belum Lulus',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 94,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${d.score}/${d.maxScore}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Dari 100 Poin',
                    style: TextStyle(fontSize: 7, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            EduCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Hasil',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  _row('Jumlah Benar', '${d.correct} Soal'),
                  _row('Jawaban Salah', '${d.wrong} Soal'),
                  _row('Nilai Minimum Lulus', '${d.passingScore}%'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.studentCourseDetail,
                (r) =>
                    r.settings.name == RouteNames.studentDashboard || r.isFirst,
                arguments: {'course_id': d.courseId},
              ),
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Ui.blueSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Ui.blue.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Kembali ke Course',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Ui.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _error(String text, {VoidCallback? onRetry}) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 11, color: Ui.muted),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Ui.bg,
    body: _result == null
        ? _error('Hasil kuis tidak ditemukan.')
        : FutureBuilder<_ResultData>(
            future: _result,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _error(
                  'Hasil kuis belum dapat dimuat.',
                  onRetry: _reload,
                );
              }
              return _content(snapshot.data!);
            },
          ),
  );
}
