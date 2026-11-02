import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';

class StudentHistoryPage extends StatelessWidget {
  const StudentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'student', current: 2),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                    Text('Matematika Kelas 10', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    Text('Quiz 1 - Latihan Soal Aljabar', style: TextStyle(fontSize: 8.5)),
                    SizedBox(height: 4),
                    Text('16 - 09 - 2026 | 16.00', style: TextStyle(fontSize: 8)),
                  ],
                ),
              ),
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Ui.greenDark),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
