import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/common/student_filter_panel.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class TeacherStudentListPage extends StatefulWidget {
  const TeacherStudentListPage({super.key});

  @override
  State<TeacherStudentListPage> createState() => _TeacherStudentListPageState();
}

class _TeacherStudentListPageState extends State<TeacherStudentListPage> {
  final _db = Supabase.instance.client;
  static const List<String> _classOptions = ['X', 'XI', 'XII'];
  static const List<String> _majorOptions = [
    'RPL A',
    'RPL B',
    'RPL C',
    'RPL D',
    'TKJ A',
    'TKJ B',
    'TKJ C',
    'TKJ D',
    'METRO A',
    'METRO B',
    'ELIN A',
    'ELIN B',
  ];
  String query = '';
  String? _classFilter;
  String? _majorFilter;
  String _sortOrder = 'A-Z';
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
        .select('id_user, username, nisn, kelas, status')
        .inFilter('id_user', studentIds);
    final accounts = {
      for (final account in accountRows) account['id_user'].toString(): account,
    };

    return List<Map<String, dynamic>>.from(profiles).map((profile) {
      final id = profile['id'].toString();
      final account = accounts[id];
      return {
        ...profile,
        'username':
            (account?['nisn'] ?? account?['username'])?.toString() ?? '-',
        'class_name': account?['kelas']?.toString() ?? '-',
        'status': account?['status']?.toString() ?? '-',
        'courses': (coursesByStudent[id] ?? {}).toList()..sort(),
      };
    }).toList();
  }

  String? _gradeFromValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final upper = value.trim().toUpperCase();

    final romanMatch = RegExp(r'XII|XI|X').firstMatch(upper);
    if (romanMatch != null) return romanMatch.group(0);

    final digits = RegExp(r'\d+').stringMatch(upper);
    if (digits == null || digits.isEmpty) return null;

    switch (digits) {
      case '10':
        return 'X';
      case '11':
        return 'XI';
      case '12':
        return 'XII';
      default:
        return null;
    }
  }

  String _majorFromClass(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    const classLabels = {
      'KELAS',
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    };
    final parts = raw.toUpperCase().split(RegExp(r'\s+')).where((part) {
      return !classLabels.contains(part) && !RegExp(r'^\d+$').hasMatch(part);
    });
    return parts.join(' ');
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
            final studentsData = snapshot.data ?? [];
            final classes = List<String>.from(_classOptions);
            final majors = List<String>.from(_majorOptions);

            final students = (studentsData).where((student) {
              final name = (student['full_name'] ?? '')
                  .toString()
                  .toLowerCase();
              final username = (student['username'] ?? '')
                  .toString()
                  .toLowerCase();
              final matchesQuery =
                  name.contains(query) || username.contains(query);
              if (!matchesQuery) return false;

              final className = student['class_name']?.toString() ?? '';
              final grade = _gradeFromValue(className);
              if (_classFilter != null && grade != _classFilter) {
                return false;
              }

              final major = _majorFromClass(className);
              if (_majorFilter != null &&
                  major.toUpperCase() != _majorFilter!.toUpperCase()) {
                return false;
              }

              return true;
            }).toList();

            students.sort((a, b) {
              final aName = (a['full_name'] ?? '').toString().toLowerCase();
              final bName = (b['full_name'] ?? '').toString().toLowerCase();
              final compare = aName.compareTo(bName);
              return _sortOrder == 'Z-A' ? -compare : compare;
            });

            return Column(
              children: [
                StudentFilterPanel(
                  classOptions: classes,
                  majorOptions: majors,
                  selectedClass: _classFilter,
                  selectedMajor: _majorFilter,
                  sortOrder: _sortOrder,
                  onApply: (selectedClass, selectedMajor, sortOrder) {
                    setState(() {
                      _classFilter = selectedClass;
                      _majorFilter = selectedMajor;
                      _sortOrder = sortOrder;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Belum ada siswa pada course Anda.',
                        style: TextStyle(fontSize: 10, color: Ui.muted),
                      ),
                    ),
                  )
                else
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
                                  Text(
                                    student['username']?.toString() ?? '-',
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
