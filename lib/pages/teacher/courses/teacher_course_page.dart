import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class _CourseItem {
  final String id;
  final String title;
  final bool isActive;
  final int materials;
  final int quizzes;
  final int students;

  const _CourseItem({
    required this.id,
    required this.title,
    required this.isActive,
    required this.materials,
    required this.quizzes,
    required this.students,
  });
}

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({super.key});
  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  static const _tCourses = 'courses';

  final _db = Supabase.instance.client;

  int filter = 0;
  bool _loading = true;
  String? _error;
  List<_CourseItem> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, int>> _countByCourse(
    String table,
    List<String> courseIds,
  ) async {
    if (courseIds.isEmpty) return {};
    final rows = await _db
        .from(table)
        .select('course_id')
        .inFilter('course_id', courseIds);
    final result = <String, int>{};
    for (final r in rows) {
      final id = r['course_id'].toString();
      result[id] = (result[id] ?? 0) + 1;
    }
    return result;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) throw 'Sesi login tidak ditemukan';

      final rows = await _db
          .from(_tCourses)
          .select('id, title, status')
          .eq('teacher_id', uid)
          .order('title');

      final ids = rows.map<String>((r) => r['id'].toString()).toList();

      final students = await _countByCourse('enrollments', ids);
      final materials = await _countByCourse('materials', ids);
      final quizzes = await _countByCourse('quizzes', ids);

      final list = rows.map<_CourseItem>((r) {
        final id = r['id'].toString();
        return _CourseItem(
          id: id,
          title: (r['title'] ?? '-').toString(),
          isActive: r['status'] == 'active',
          materials: materials[id] ?? 0,
          quizzes: quizzes[id] ?? 0,
          students: students[id] ?? 0,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _courses = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('TeacherCoursesPage error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(_CourseItem c) async {
    await Navigator.pushNamed(
      context,
      RouteNames.teacherCourseDetail,
      arguments: c.id,
    );
    if (mounted) _load();
  }

  Widget _stateBox(String text, {bool retry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Ui.muted),
            ),
            if (retry) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _courses.where((e) {
      if (filter == 1) return e.isActive;
      if (filter == 2) return !e.isActive;
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
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _stateBox('Gagal memuat course.\n$_error', retry: true)
          else if (items.isEmpty)
            _stateBox('Belum ada course')
          else
            for (final c in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EduCard(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  onTap: () => _openDetail(c),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Pill(
                            c.isActive ? 'Aktif' : 'Nonaktif',
                            kind: c.isActive
                                ? PillKind.active
                                : PillKind.inactive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.materials} Materi • ${c.quizzes} Quiz',
                        style: const TextStyle(fontSize: 8.5),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFEEF1F6)),
                      const SizedBox(height: 6),
                      Text(
                        '${c.students} Siswa',
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
