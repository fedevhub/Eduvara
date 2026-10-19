import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/mock/mock_data.dart';

class TeacherStudentDetailPage extends StatelessWidget {
  const TeacherStudentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final u = arg is MockUser ? arg : mockSiswa.first;
    return EduScaffold(
      bottom: const EduBottomNav(role: 'teacher', current: 2),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackLink(),
          EduCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Ui.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      u.info.split(' ').take(2).join(' '),
                      style: const TextStyle(fontSize: 9),
                    ),
                    const SizedBox(height: 3),
                    Pill(
                      u.active ? 'Aktif' : 'Nonaktif',
                      kind: u.active ? PillKind.active : PillKind.inactive,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: StatBox(value: '15%', label: 'Progress')),
              SizedBox(width: 10),
              Expanded(child: StatBox(value: '80', label: 'Avg Quiz')),
              SizedBox(width: 10),
              Expanded(child: StatBox(value: '6', label: 'Materi')),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Progress per Materi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const _MateriProgress('Matematika Dasar Kelas 10', 1.0, Ui.green, '100%'),
          const SizedBox(height: 8),
          const _MateriProgress('Matematika Kelas 10', 0.6, Ui.blue, '60%'),
          const SizedBox(height: 14),
          const Text(
            'Hasil Quiz',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          EduCard(
            borderColor: Ui.green,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Ui.greenSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check, size: 15, color: Ui.greenDark),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz 1 - Latihan Soal Aljabar',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '10 Soal | 30 Menit',
                        style: TextStyle(fontSize: 8.5),
                      ),
                    ],
                  ),
                ),
                const _ScoreBadge(80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MateriProgress extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final String label;
  const _MateriProgress(this.title, this.value, this.color, this.label);

  @override
  Widget build(BuildContext context) => EduCard(
    borderColor: color,
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressLine(value: value, color: color),
      ],
    ),
  );
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge(this.score);

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Ui.greenSoft,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      '$score',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Ui.greenDark,
      ),
    ),
  );
}
