import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class StudentCourseDetailPage extends StatefulWidget {
  const StudentCourseDetailPage({super.key});
  @override
  State<StudentCourseDetailPage> createState() =>
      _StudentCourseDetailPageState();
}

class _StudentCourseDetailPageState extends State<StudentCourseDetailPage> {
  int tab = 0;

  Widget _item(String title, String sub, {bool open = false, bool done = false}) {
    final card = EduCard(
      borderColor: open ? Ui.blue : (done ? Ui.green : null),
      padding: const EdgeInsets.all(12),
      onTap: open || done
          ? () => Navigator.pushNamed(
              context,
              tab == 0
                  ? RouteNames.studentMaterialDetail
                  : RouteNames.studentQuiz,
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                Text(sub, style: const TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          if (open || done)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? Ui.greenSoft : Ui.blueSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                done ? Icons.check : Icons.arrow_forward,
                size: 14,
                color: done ? Ui.greenDark : Ui.blue,
              ),
            ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: open || done
          ? card
          : LockedCard(
              text: tab == 0
                  ? 'Selesaikan Modul Sebelumnya'
                  : 'Selesaikan Quiz Sebelumnya',
              child: card,
            ),
    );
  }

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
            Expanded(child: StatBox(value: '1/6', label: 'Berjalan')),
            SizedBox(width: 10),
            Expanded(child: StatBox(value: '10%', label: 'Progress')),
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
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                tab == 0 ? 'Daftar Course' : 'Daftar Quiz',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              tab == 0 ? '0/6' : '1/3',
              style: const TextStyle(fontSize: 10, color: Ui.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tab == 0) ...[
          _item('Aljabar', 'Senin, 15-09-2026', open: true),
          _item('Eksponen', 'Senin, 15-09-2026'),
          _item('Linear', 'Senin, 15-09-2026'),
          _item('Aljabar', 'Senin, 15-09-2026'),
        ] else ...[
          _item('Quiz 1 - Latihan Soal Aljabar', '10 Soal | 30 Menit', open: true),
          _item('Quiz 2 - Soal Eksponen', '20 Soal | 60 Menit'),
          _item('Quiz 3 - UH Aljabar', '20 Soal | 60 Menit'),
        ],
      ],
    ),
  );
}
