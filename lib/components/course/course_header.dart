import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../core/constants/app_colors.dart';

class CourseHeader extends StatelessWidget {
  final Course course;
  const CourseHeader({super.key, required this.course});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.menu_book_rounded, color: Colors.white, size: 34),
        const SizedBox(height: 18),
        Text(
          course.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          course.description,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
      ],
    ),
  );
}
