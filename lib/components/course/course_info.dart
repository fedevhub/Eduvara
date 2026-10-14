import 'package:flutter/material.dart';
import '../../models/course_model.dart';

class CourseInfo extends StatelessWidget {
  final Course course;
  const CourseInfo({super.key, required this.course});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _item(
          Icons.person_outline,
          'Pengajar',
          course.teacher.isEmpty ? '-' : course.teacher,
        ),
      ),
      Expanded(
        child: _item(Icons.check_circle_outline, 'Status', course.status),
      ),
    ],
  );

  Widget _item(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}
