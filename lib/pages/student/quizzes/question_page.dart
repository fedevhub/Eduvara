import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class _Soal {
  final String id;
  final String q;
  final List<String> options;
  const _Soal(this.id, this.q, this.options);
}

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});
  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final _db = Supabase.instance.client;

  List<_Soal> _soal = [];
  int current = 0;
  final Map<int, int> answers = {};
  Duration remaining = Duration.zero;
  Timer? _timer;
  bool _finishing = false;
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  String _quizTitle = 'Quiz';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final quizId = arguments is Map ? arguments['id']?.toString() : null;
    if (quizId == null || quizId.isEmpty) {
      setState(() {
        _error = 'Quiz tidak ditemukan. Kembali ke course dan coba lagi.';
        _loading = false;
      });
      return;
    }

    try {
      final quiz = await _db
          .from('quizzes')
          .select('title, duration_minutes')
          .eq('id', quizId)
          .single();
      final rows = await _db.rpc(
        'get_student_quiz_questions',
        params: {'p_quiz_id': quizId},
      );
      final questions = List<Map<String, dynamic>>.from(rows)
          .map(
            (row) =>
                _Soal(row['id'].toString(), row['question']?.toString() ?? '', [
                  row['option_a']?.toString() ?? '',
                  row['option_b']?.toString() ?? '',
                  row['option_c']?.toString() ?? '',
                  row['option_d']?.toString() ?? '',
                ]),
          )
          .toList();
      if (questions.isEmpty) {
        throw Exception('Quiz ini belum memiliki soal.');
      }

      final userId = _db.auth.currentUser?.id;
      if (userId != null) {
        final finished = await _db
            .from('quiz_attempts')
            .select('id, completed')
            .eq('user_id', userId)
            .eq('quiz_id', quizId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (finished != null && finished['completed'] == true) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            RouteNames.studentQuizResult,
            arguments: {
              'attempt_id': finished['id'],
              'entity_name': quiz['title'],
            },
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _quizTitle = quiz['title']?.toString() ?? 'Quiz';
        _soal = questions;
        remaining = Duration(
          minutes: (quiz['duration_minutes'] as num?)?.toInt() ?? 20,
        );
        _loading = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat soal quiz: $e';
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remaining.inSeconds <= 0) {
        _timer?.cancel();
        unawaited(_finish());
        return;
      }
      setState(() => remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clock {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(remaining.inMinutes)}.${two(remaining.inSeconds % 60)}.00';
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final quizTitle = _quizTitle;
    try {
      final quizId = arguments is Map ? arguments['id']?.toString() : null;
      final userId = _db.auth.currentUser?.id;
      if (quizId == null || quizId.isEmpty) {
        throw Exception(
          'Quiz tidak ditemukan. Kembali ke course dan coba lagi.',
        );
      }
      if (userId == null) {
        throw Exception('Sesi login berakhir, silakan login ulang.');
      }

      var correct = 0;
      var earnedPoints = 0;
      final totalPoints = _soal.fold<int>(
        0,
        (total, question) => total + question.points,
      );
      for (var i = 0; i < _soal.length; i++) {
        if (answers[i] == _soal[i].correctOption) {
          correct++;
          earnedPoints += _soal[i].points;
        }
      }
      final wrong = _soal.length - correct;
      final score = totalPoints == 0
          ? 0
          : (earnedPoints / totalPoints * 100).round();
      final attempt = await _db
          .from('quiz_attempts')
          .insert({
            'user_id': userId,
            'quiz_id': quizId,
            'score': score,
            'correct_count': correct,
            'wrong_count': wrong,
            'completed': true,
          })
          .select('id')
          .single();

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.studentQuizResult,
          arguments: {'attempt_id': attemptId, 'entity_name': quizTitle},
        );
      }
    } catch (e) {
      _finishing = false;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan hasil quiz: $e')));
    }
  }

  Future<void> _submit() async {
    final ok = await showEduDialog(
      context,
      icon: Icons.warning_amber_rounded,
      iconColor: Ui.orange,
      iconBg: Ui.yellowSoft,
      title: 'Submit Quiz',
      message:
          'Quiz hanya dapat dikerjakan satu kali dan jawaban tidak dapat diubah.',
      primary: 'Ya, Submit',
      secondary: 'Periksa Lagi',
    );
    if (ok && mounted) await _finish();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Ui.bg,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_error != null) {
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
                    _error!,
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
    final soal = _soal[current];
    final last = current == _soal.length - 1;
    return Scaffold(
      backgroundColor: Ui.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                boxShadow: Ui.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: BackLink(),
                        ),
                      ),
                      Text(
                        _clock,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var i = 0; i < _soal.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => current = i),
                          child: Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == current
                                  ? Ui.blue
                                  : (answers.containsKey(i)
                                        ? Ui.green
                                        : Ui.blueTint),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: i == current || answers.containsKey(i)
                                    ? Colors.white
                                    : Ui.muted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                children: [
                  EduCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _chip('${current + 1}', false),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            soal.q,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < soal.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => answers[current] = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: answers[current] == i
                                ? Ui.blueTint
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: answers[current] == i ? Ui.blue : Ui.line,
                            ),
                            boxShadow: Ui.shadow,
                          ),
                          child: Row(
                            children: [
                              _chip(
                                String.fromCharCode(65 + i),
                                answers[current] == i,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                soal.options[i],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                10 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: Ui.shadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SolidBtn(
                      label: 'Kembali',
                      leading: Icons.arrow_back,
                      bg: const Color(0xFFD1D5DB),
                      fg: Ui.text,
                      height: 34,
                      onTap: current == 0
                          ? null
                          : () => setState(() => current--),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SolidBtn(
                      label: last ? 'Submit' : 'Selanjutnya',
                      trailing: Icons.arrow_forward,
                      bg: Ui.blue,
                      height: 34,
                      onTap: last ? _submit : () => setState(() => current++),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, bool active) => Container(
    width: 20,
    height: 20,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: active ? Ui.blue : Ui.blueTint,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: active ? Colors.white : Ui.blue,
      ),
    ),
  );
}
