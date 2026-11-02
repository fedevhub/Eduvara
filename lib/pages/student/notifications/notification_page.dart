import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';

class StudentNotificationPage extends StatelessWidget {
  const StudentNotificationPage({super.key});

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'student', current: 3),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text('Notification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        const Text('Hari Ini', style: TextStyle(fontSize: 10)),
        const SizedBox(height: 8),
        const EduCard(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Materi Baru Ditambahkan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  Text('10 Menit Lalu', style: TextStyle(fontSize: 7.5, color: Ui.muted)),
                ],
              ),
              SizedBox(height: 4),
              Text('Budi Santoso menambahkan materi "Eksponen"', style: TextStyle(fontSize: 8.5)),
            ],
          ),
        ),
      ],
    ),
  );
}
