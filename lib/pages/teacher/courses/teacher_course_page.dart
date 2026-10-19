import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({super.key});
  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  int filter = 0;

  static const _data = [
    ('Matematika Kelas 10', '6 Materi', '3 Quiz', '34 Siswa', true),
    ('Matematika Kelas 11', '8 Materi', '3 Quiz', '28 Siswa', true),
    ('Matematika Kelas 12', '5 Materi', '1 Quiz', '0 Siswa', false),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _data.where((e) {
      if (filter == 1) return e.$5;
      if (filter == 2) return !e.$5;
      return true;
    }).toList();
    return EduScaffold(
      bottom: const EduBottomNav(role: 'teacher', current: 1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'Course',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          FilterChips(
            labels: const ['Semua', 'Aktif', 'Nonaktif'],
            index: filter,
            onChanged: (i) => setState(() => filter = i),
          ),
          const SizedBox(height: 12),
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EduCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.teacherCourseDetail,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.$1,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Pill(
                          c.$5 ? 'Aktif' : 'Nonaktif',
                          kind: c.$5 ? PillKind.active : PillKind.inactive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.$2} • ${c.$3}',
                      style: const TextStyle(fontSize: 8.5),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFEEF1F6)),
                    const SizedBox(height: 6),
                    Text(
                      c.$4,
                      style: const TextStyle(fontSize: 8.5, color: Ui.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
