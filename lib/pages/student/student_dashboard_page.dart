import 'package:flutter/material.dart';
import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  Widget _metric(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Ui.greenDark,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 8, color: Ui.muted)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'student', current: 0),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panel Student', style: TextStyle(fontSize: 11)),
                  Text(
                    'Fitri Rachmania',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            DarkAvatar(size: 34),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Ui.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress Belajar Kamu!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metric('1', 'Selesai'),
                  const SizedBox(width: 8),
                  _metric('1', 'Berjalan'),
                  const SizedBox(width: 8),
                  _metric('3', 'Terkunci'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Lanjutkan Belajar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            GestureDetector(
              onTap: () =>
                  Navigator.pushReplacementNamed(context, RouteNames.studentCourses),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Ui.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        EduCard(
          borderColor: Ui.blue,
          padding: const EdgeInsets.all(12),
          onTap: () =>
              Navigator.pushNamed(context, RouteNames.studentCourseDetail),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Matematika Kelas 10',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Text('Budi Santoso • 5 Materi', style: TextStyle(fontSize: 8.5)),
                    SizedBox(height: 8),
                    Text(
                      '60% Selesai',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Ui.blue,
                      ),
                    ),
                    SizedBox(height: 3),
                    ProgressLine(value: 0.6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Ui.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LockedCard(
          text: 'Selesaikan Course Sebelumnya',
          child: EduCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matematika Kelas 10',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      Text('Budi Santoso • 5 Materi', style: TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
