import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';

class TeacherNotificationPage extends StatelessWidget {
  const TeacherNotificationPage({super.key});

  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        const SizedBox(height: 4),
        const Text(
          'Notification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        const Text('Hari Ini', style: TextStyle(fontSize: 10)),
        const SizedBox(height: 8),
        EduCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quiz Baru Dikerjakan',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '10 Menit Lalu',
                    style: TextStyle(fontSize: 7.5, color: Ui.muted),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Fitri Rachmania menyelesaikan "Quiz 1 - Latihan Soal Aljabar"',
                style: TextStyle(fontSize: 8.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
