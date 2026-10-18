import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

/// "Memulai quiz" - informasi quiz sebelum dikerjakan.
class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontSize: 9))),
        Text(v, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        const Text('Aljabar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        EduCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informasi Quiz', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              _row('Jumlah Soal', '5 Soal'),
              _row('Durasi', '20 Menit'),
              _row('Nilai Lulus', '80/100'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, RouteNames.studentQuestion),
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Ui.blueSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Ui.blue.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'Mulai Quiz Sekarang',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Ui.blue),
            ),
          ),
        ),
      ],
    ),
  );
}