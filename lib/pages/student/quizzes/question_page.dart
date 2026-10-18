import 'dart:async';
import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class _Soal {
  final String q;
  final List<String> options;
  const _Soal(this.q, this.options);
}

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});
  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  static const _soal = [
    _Soal('Sederhanakan bentuk aljabar berikut: 3x + 5x − 2x = ...', ['4x', '5x', '6x', '10x']),
    _Soal('Diketahui x = 4. Berapakah nilai dari 2x + 7?', ['11', '13', '15', '17']),
    _Soal('Koefisien dari variabel x pada bentuk aljabar 7x + 3 adalah ...', ['3', '7', 'x', '10']),
    _Soal('Hasil dari 5a − 2a + a adalah ...', ['2a', '3a', '4a', '8a']),
    _Soal('Jika 2x + 6 = 14, maka nilai x adalah ...', ['2', '3', '4', '5']),
  ];

  int current = 0;
  final Map<int, int> answers = {};
  Duration remaining = const Duration(minutes: 20);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remaining.inSeconds <= 0) {
        _timer?.cancel();
        _finish();
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

  void _finish() {
    _timer?.cancel();
    Navigator.pushReplacementNamed(context, RouteNames.studentQuizResult);
  }

  Future<void> _submit() async {
    final ok = await showEduDialog(
      context,
      icon: Icons.warning_amber_rounded,
      iconColor: Ui.orange,
      iconBg: Ui.yellowSoft,
      title: 'Submit Quiz',
      message: 'Quiz hanya dapat dikerjakan satu kali dan jawaban tidak dapat diubah.',
      primary: 'Ya, Submit',
      secondary: 'Periksa Lagi',
    );
    if (ok && mounted) _finish();
  }

  @override
  Widget build(BuildContext context) {
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                boxShadow: Ui.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Align(alignment: Alignment.centerLeft, child: BackLink())),
                      Text(_clock, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
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
                                  : (answers.containsKey(i) ? Ui.green : Ui.blueTint),
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
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: answers[current] == i ? Ui.blueTint : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: answers[current] == i ? Ui.blue : Ui.line,
                            ),
                            boxShadow: Ui.shadow,
                          ),
                          child: Row(
                            children: [
                              _chip(String.fromCharCode(65 + i), answers[current] == i),
                              const SizedBox(width: 12),
                              Text(
                                soal.options[i],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                      onTap: current == 0 ? null : () => setState(() => current--),
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
