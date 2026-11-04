import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class TeacherStudentListPage extends StatefulWidget {
  const TeacherStudentListPage({super.key});

  @override
  State<TeacherStudentListPage> createState() => _TeacherStudentListPageState();
}

class _TeacherStudentListPageState extends State<TeacherStudentListPage> {
  final _db = Supabase.instance.client;
  String query = '';
  late Future<List<Map<String, dynamic>>> _students;

  @override
  void initState() {
    super.initState();
    _students = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final teacherId = _db.auth.currentUser?.id;
    if (teacherId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final courses = await _db
        .from('courses')
        .select('id, title')
        .eq('teacher_id', teacherId);
    if (courses.isEmpty) return const [];

    final courseNames = {
      for (final course in courses)
        course['id'].toString(): (course['title'] ?? 'Course').toString(),
    };
    final enrollments = await _db
        .from('enrollments')
        .select('student_id, course_id')
        .inFilter('course_id', courseNames.keys.toList());

    final coursesByStudent = <String, Set<String>>{};
    for (final enrollment in enrollments) {
      final studentId = enrollment['student_id'].toString();
      final courseTitle =
          courseNames[enrollment['course_id'].toString()] ?? 'Course';
      coursesByStudent
          .putIfAbsent(studentId, () => <String>{})
          .add(courseTitle);
    }
    if (coursesByStudent.isEmpty) return const [];

    final studentIds = coursesByStudent.keys.toList();
    final profiles = await _db
        .from('profiles')
        .select('id, full_name, role')
        .eq('role', 'student')
        .inFilter('id', studentIds)
        .order('full_name');
    final accountRows = await _db
        .from('user')
        .select('id_user, email, kelas, status')
        .inFilter('id_user', studentIds);
    final accounts = {
      for (final account in accountRows) account['id_user'].toString(): account,
    };

    return List<Map<String, dynamic>>.from(profiles).map((profile) {
      final id = profile['id'].toString();
      final account = accounts[id];
      return {
        ...profile,
        'email': account?['email']?.toString() ?? '-',
        'class_name': account?['kelas']?.toString() ?? '-',
        'status': account?['status']?.toString() ?? '-',
        'courses': (coursesByStudent[id] ?? {}).toList()..sort(),
      };
    }).toList();
  }

  void _reload() => setState(() => _students = _load());

  @override
  Widget build(BuildContext context) => EduScaffold(
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
          onChanged: (value) =>
              setState(() => query = value.trim().toLowerCase()),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _students,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    'Daftar siswa belum dapat dimuat.\n${snapshot.error}',
                    style: const TextStyle(fontSize: 10, color: Ui.muted),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }
            final students = (snapshot.data ?? []).where((student) {
              final name = (student['full_name'] ?? '')
                  .toString()
                  .toLowerCase();
              final email = (student['email'] ?? '').toString().toLowerCase();
              return name.contains(query) || email.contains(query);
            }).toList();
            if (students.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Belum ada siswa pada course Anda.',
                    style: TextStyle(fontSize: 10, color: Ui.muted),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final student in students)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EduCard(
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.teacherStudentDetail,
                        arguments: student,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          DarkAvatar(
                            name: student['full_name']?.toString(),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['full_name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  student['class_name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    color: Ui.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
