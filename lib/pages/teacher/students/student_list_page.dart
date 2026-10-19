import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/routes/route_names.dart';

class TeacherStudentListPage extends StatefulWidget {
  const TeacherStudentListPage({super.key});
  @override
  State<TeacherStudentListPage> createState() => _TeacherStudentListPageState();
}

class _TeacherStudentListPageState extends State<TeacherStudentListPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final items = mockSiswa
        .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return EduScaffold(
      bottom: const EduBottomNav(role: 'teacher', current: 2),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'Daftar Siswa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SearchBox(
            hint: 'Cari Siswa',
            pill: true,
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 12),
          for (final u in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EduCard(
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.teacherStudentDetail,
                  arguments: u,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    const DarkAvatar(size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            u.info.split(' ').take(2).join(' '),
                            style: const TextStyle(fontSize: 8.5),
                          ),
                        ],
                      ),
                    ),
                    Pill(
                      u.active ? 'Aktif' : 'Nonaktif',
                      kind: u.active ? PillKind.active : PillKind.inactive,
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
