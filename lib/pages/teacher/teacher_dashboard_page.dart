import 'package:flutter/material.dart';
import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'teacher', current: 0),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panel Teacher', style: TextStyle(fontSize: 11)),
                  Text(
                    'Budi Santoso',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                RouteNames.teacherNotifications,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, size: 24),
                  Positioned(
                    right: 1,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Ui.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const DarkAvatar(size: 34),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: StatBox(
                value: '3',
                label: 'Total Kursus',
                icon: Icons.menu_book_outlined,
                tall: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatBox(
                value: '62',
                label: 'Total Siswa',
                icon: Icons.groups_outlined,
                tall: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: StatBox(
                value: '72%',
                label: 'Avg Completion',
                icon: Icons.bar_chart,
                tall: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatBox(
                value: '80',
                label: 'Avg Quiz Score',
                icon: Icons.gps_fixed,
                tall: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Kursus Aktif',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _ActiveCourse(
          title: 'Aljabar',
          info: '34 siswa • 72% selesai',
          value: 0.72,
          onTap: () =>
              Navigator.pushNamed(context, RouteNames.teacherCourseDetail),
        ),
        const SizedBox(height: 10),
        _ActiveCourse(
          title: 'Eksponen',
          info: '15 siswa • 20% selesai',
          value: 0.20,
          onTap: () =>
              Navigator.pushNamed(context, RouteNames.teacherCourseDetail),
        ),
      ],
    ),
  );
}

class _ActiveCourse extends StatelessWidget {
  final String title;
  final String info;
  final double value;
  final VoidCallback onTap;
  const _ActiveCourse({
    required this.title,
    required this.info,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => EduCard(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(info, style: const TextStyle(fontSize: 8.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
        const SizedBox(height: 8),
        ProgressLine(value: value, height: 5),
      ],
    ),
  );
}
