import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../core/constants/app_colors.dart';

class QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback? onTap;
  const QuizCard({super.key, required this.quiz, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF4)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.quiz_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quiz.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${quiz.questionCount} soal',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}
