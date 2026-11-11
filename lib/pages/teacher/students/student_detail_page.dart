import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';

class TeacherStudentDetailPage extends StatefulWidget {
  const TeacherStudentDetailPage({super.key});

  @override
  State<TeacherStudentDetailPage> createState() =>
      _TeacherStudentDetailPageState();
}

class _TeacherStudentDetailPageState extends State<TeacherStudentDetailPage> {
  final _db = Supabase.instance.client;
  String? _studentId;
  Future<Map<String, dynamic>>? _student;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_studentId != null) return;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) _studentId = arguments['id']?.toString();
    if (_studentId != null && _studentId!.isNotEmpty) _student = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final id = _studentId!;
    final profile = await _db
        .from('profiles')
        .select('id, full_name, role')
        .eq('id', id)
        .eq('role', 'student')
        .single();
    final account = await _db
        .from('user')
        .select('username, nisn, kelas, status')
        .eq('id_user', id)
        .maybeSingle();
    final enrollments = await _db
        .from('enrollments')
        .select('course_id')
        .eq('student_id', id);
    final courseIds = enrollments
        .map((row) => row['course_id'].toString())
        .toSet()
        .toList();
    final courses = courseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _db
                .from('courses')
                .select('id, title')
                .inFilter('id', courseIds),
          );
    courses.sort(
      (a, b) => (a['title'] ?? '').toString().compareTo(
        (b['title'] ?? '').toString(),
      ),
    );

    return {
      'id': id,
      'full_name': profile['full_name'] ?? '-',
      'username': account?['nisn'] ?? account?['username'] ?? '-',
      'class_name': account?['kelas'] ?? '-',
      'status': account?['status'] ?? '-',
      'courses': courses
          .map((course) => course['title']?.toString() ?? '-')
          .toList(),
    };
  }

  Widget _info(String label, String value, {bool last = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: Ui.muted),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_student == null) {
      return EduScaffold(
        bottom: const EduBottomNav(role: 'teacher', current: 2),
        body: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Informasi siswa tidak tersedia.',
                style: TextStyle(fontSize: 11, color: Ui.muted),
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _student,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const EduScaffold(
            bottom: EduBottomNav(role: 'teacher', current: 2),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return EduScaffold(
            bottom: const EduBottomNav(role: 'teacher', current: 2),
            body: Column(
              children: [
                const BackLink(),
                Text(
                  'Profil siswa belum dapat dimuat.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Ui.muted),
                ),
              ],
            ),
          );
        }

        final student = snapshot.data!;
        final name = student['full_name']?.toString() ?? '-';
        final courses = (student['courses'] as List? ?? const [])
            .map((course) => course.toString())
            .toList();
        final status = student['status']?.toString() ?? '-';
        final username = student['username']?.toString() ?? '-';

        return Scaffold(
          backgroundColor: Ui.bg,
          bottomNavigationBar: const EduBottomNav(role: 'teacher', current: 2),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 8,
                    20,
                    22,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0xFF93B4F8), Ui.blue],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BackLink(),
                      ),
                      const SizedBox(height: 4),
                      DarkAvatar(name: name, size: 64),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EduCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Akun',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _info('Username', username),
                            _info('Role', 'Siswa'),
                            _info('Status', status),
                            _info(
                              'Kelas',
                              student['class_name']?.toString() ?? '-',
                              last: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Course Diikuti',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (courses.isEmpty)
                        const Text(
                          'Belum terdaftar pada course.',
                          style: TextStyle(fontSize: 10, color: Ui.muted),
                        )
                      else
                        for (final course in courses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EduCard(
                              padding: const EdgeInsets.all(11),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.menu_book_outlined,
                                    size: 16,
                                    color: Ui.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      course,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
