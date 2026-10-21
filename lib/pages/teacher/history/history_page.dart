import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';

class TeacherHistoryPage extends StatelessWidget {
  const TeacherHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'teacher', current: 3),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text(
          'History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('Hari Ini', style: TextStyle(fontSize: 10)),
        const SizedBox(height: 8),
        EduCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitri Rachmania',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Quiz 1 - Latihan Soal Aljabar',
                      style: TextStyle(fontSize: 8.5),
                    ),
                    SizedBox(height: 4),
                    Text('16 - 09 - 2026 | 16.00', style: TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '10 Menit Lalu',
                    style: TextStyle(fontSize: 7.5, color: Ui.muted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Ui.greenSoft,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      '80',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Ui.greenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
