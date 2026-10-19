import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class TeacherCourseDetailPage extends StatefulWidget {
  const TeacherCourseDetailPage({super.key});
  @override
  State<TeacherCourseDetailPage> createState() =>
      _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  int tab = 0;

  static const _materi = ['Aljabar', 'Eksponen', 'Linear', 'Aljabar', 'Eksponen'];
  static const _quiz = [
    ('Quiz 1 - Latihan Soal Aljabar', '10 Soal | 30 Menit'),
    ('Quiz 2 - Pengenalan Eksponen', '10 Soal | 30 Menit'),
    ('Quiz 3 - UH Aljabar', '10 Soal | 30 Menit'),
  ];

  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        const Text(
          'Matematika Kelas 10',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const Text('Budi Santoso', style: TextStyle(fontSize: 9)),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: StatBox(value: '6', label: 'Materi')),
            SizedBox(width: 10),
            Expanded(child: StatBox(value: '3', label: 'Quiz')),
            SizedBox(width: 10),
            Expanded(child: StatBox(value: '72%', label: 'Selesai')),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Kuasai aljabar, geometri, dan kalkulus dasar untuk persiapan ujian.',
          style: TextStyle(fontSize: 9),
        ),
        const SizedBox(height: 10),
        SegTabs(
          labels: const ['Course', 'Quiz'],
          index: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        const SizedBox(height: 12),
        if (tab == 0) ..._courseTab() else ..._quizTab(),
      ],
    ),
  );

  Widget _manageButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Ui.blueSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Ui.blue.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 15, color: Ui.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Ui.blue,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _iconBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: fg),
        ),
      );

  Future<void> _delete(String what) async {
    final ok = await showConfirmDanger(
      context,
      title: 'Hapus $what?',
      message: 'Data yang dihapus tidak dapat dikembalikan.',
    );
    if (ok && mounted) await showSuccessDialog(context, '$what Berhasil di Hapus');
  }

  List<Widget> _courseTab() => [
    _manageButton(
      'Tambah / Kelola Materi',
      () => Navigator.pushNamed(context, RouteNames.teacherMaterialForm),
    ),
    const SizedBox(height: 12),
    const Text(
      'Daftar Course',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    for (final m in _materi)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EduCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Senin, 15-09-2026',
                      style: TextStyle(fontSize: 8.5),
                    ),
                  ],
                ),
              ),
              _iconBtn(
                Icons.edit_outlined,
                Ui.blueSoft,
                Ui.blue,
                () => Navigator.pushNamed(
                  context,
                  RouteNames.teacherMaterialForm,
                  arguments: m,
                ),
              ),
              _iconBtn(
                Icons.delete_outline,
                Ui.redSoft,
                Ui.red,
                () => _delete('Materi'),
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _quizTab() => [
    _manageButton(
      'Tambah / Kelola Quiz',
      () => Navigator.pushNamed(context, RouteNames.teacherQuizForm),
    ),
    const SizedBox(height: 12),
    const Text(
      'Daftar Quiz',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    for (final q in _quiz)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EduCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(q.$2, style: const TextStyle(fontSize: 8.5)),
                  ],
                ),
              ),
              _iconBtn(
                Icons.edit_outlined,
                Ui.blueSoft,
                Ui.blue,
                () => Navigator.pushNamed(
                  context,
                  RouteNames.teacherQuestionForm,
                ),
              ),
              _iconBtn(
                Icons.delete_outline,
                Ui.redSoft,
                Ui.red,
                () => _delete('Quiz'),
              ),
            ],
          ),
        ),
      ),
  ];
}
