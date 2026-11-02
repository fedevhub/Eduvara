import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class _Q {
  final question = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  final points = TextEditingController(text: '20');
  int correct = 0;

  void dispose() {
    question.dispose();
    points.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

/// "Tambah Soal Quiz" - daftar soal + Draft / Tambah Soal / Publikasikan.
class TeacherQuestionFormPage extends StatefulWidget {
  const TeacherQuestionFormPage({super.key});
  @override
  State<TeacherQuestionFormPage> createState() =>
      _TeacherQuestionFormPageState();
}

class _TeacherQuestionFormPageState extends State<TeacherQuestionFormPage> {
  final List<_Q> questions = [_Q()];

  @override
  void dispose() {
    for (final q in questions) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _publish() async {
    final ok = await showConfirmWarning(
      context,
      title: 'Publikasi Quiz?',
      message: 'Anda yakin ingin mempublish quiz ini ?',
      primary: 'Ya, Yakin',
    );
    if (!ok || !mounted) return;
    await showSuccessDialog(context, 'Quiz Berhasil Dipublikasikan!');
    if (!mounted) return;
    Navigator.popUntil(
      context,
      (r) => r.settings.name == RouteNames.teacherCourseDetail || r.isFirst,
    );
  }

  Widget _questionBlock(int index, _Q q) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EduCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _chip('${index + 1}', true),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: q.question,
                maxLines: null,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Tulis pertanyaan disini',
                  hintStyle: TextStyle(fontSize: 10, color: Color(0xFFB6BFCC)),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => q.correct = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: q.correct == i ? Ui.blueTint : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: q.correct == i ? Ui.blue : Ui.line,
                ),
                boxShadow: Ui.shadow,
              ),
              child: Row(
                children: [
                  _chip(String.fromCharCode(65 + i), q.correct == i),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: q.options[i],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Pilihan jawaban',
                        hintStyle: TextStyle(fontSize: 10, color: Color(0xFFB6BFCC)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.only(top: 4, bottom: 4),
        child: Text('Nilai', style: TextStyle(fontSize: 10)),
      ),
      Row(
        children: [
          SizedBox(
            width: 110,
            child: EduField(
              hint: '20',
              controller: q.points,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Poin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );

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

  @override
  Widget build(BuildContext context) => Scaffold(
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackLink(),
                Text(
                  'Tambah Soal Quiz',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              children: [
                for (var i = 0; i < questions.length; i++)
                  _questionBlock(i, questions[i]),
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
                    label: 'Draft',
                    bg: const Color(0xFFD1D5DB),
                    fg: Ui.text,
                    height: 34,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SolidBtn(
                    label: 'Tambah Soal',
                    bg: Ui.blue,
                    height: 34,
                    onTap: () => setState(() => questions.add(_Q())),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SolidBtn(
                    label: 'Publikasikan',
                    bg: Ui.green,
                    height: 34,
                    onTap: _publish,
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
