import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';
import 'course_detail_page.dart';
import 'course_form_page.dart';

/// Nama tabel Supabase (ubah di sini kalau berbeda)
const _tCourse = 'courses';
const _tProfiles = 'profiles';

class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key});
  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  final SupabaseClient _db = Supabase.instance.client;

  List<Map<String, dynamic>> _courses = [];
  Map<String, String> _teacherNames = {}; // id profil -> nama
  String query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------------------------------------------------------------------------
  // Helper pembaca kolom (fleksibel terhadap nama kolom)
  // ---------------------------------------------------------------------------
  dynamic _pick(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      if (row.containsKey(k) && row[k] != null) return row[k];
    }
    return null;
  }

  static const _idKeys = ['id', 'course_id', 'id_course', 'kode_course'];

  String? _idKey(Map<String, dynamic> row) {
    for (final k in _idKeys) {
      if (row.containsKey(k) && row[k] != null) return k;
    }
    return null;
  }

  String _title(Map<String, dynamic> c) =>
      (_pick(c, ['title', 'name', 'nama', 'judul']) ?? '-').toString();

  String _subject(Map<String, dynamic> c) =>
      (_pick(c, ['subject', 'mapel', 'category', 'kategori']) ?? '-')
          .toString();

  String _teacher(Map<String, dynamic> c) {
    final direct = _pick(c, ['teacher', 'teacher_name', 'guru', 'nama_guru']);
    if (direct != null) return direct.toString();
    final tid = _pick(c, ['teacher_id', 'guru_id', 'user_id', 'created_by']);
    if (tid != null) return _teacherNames['$tid'] ?? '-';
    return '-';
  }

  int _students(Map<String, dynamic> c) {
    final raw = _pick(c, ['students', 'student_count', 'total_students']);
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  int _percent(Map<String, dynamic> c) {
    final raw = _pick(c, ['completion_rate', 'percent', 'progress']);
    final v = raw is num ? raw.round() : int.tryParse('$raw') ?? 0;
    return v.clamp(0, 100).toInt();
  }

  bool _active(Map<String, dynamic> c) {
    final raw = _pick(c, ['active', 'is_active', 'status']);
    if (raw == null) return true;
    if (raw is bool) return raw;
    final s = '$raw'.toLowerCase().trim();
    return s == 'true' || s == 'active' || s == 'aktif' || s == '1';
  }

  // ---------------------------------------------------------------------------
  // Supabase
  // ---------------------------------------------------------------------------
  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _db.from(_tCourse).select('*'),
        _db.from('enrollments').select('course_id, student_id'),
        _db.from('materials').select('id, course_id'),
        _db.from('material_progress').select('user_id, material_id, completed'),
        _db.from('quizzes').select('id, course_id, status'),
        _db.from('quiz_attempts').select('user_id, quiz_id, completed'),
      ]);
      final courses = List<Map<String, dynamic>>.from(results[0] as List);
      final enrollments = List<Map<String, dynamic>>.from(results[1] as List);
      final materials = List<Map<String, dynamic>>.from(results[2] as List);
      final materialProgress = List<Map<String, dynamic>>.from(
        results[3] as List,
      );
      final quizzes = List<Map<String, dynamic>>.from(results[4] as List);
      final quizAttempts = List<Map<String, dynamic>>.from(results[5] as List);

      final enrollmentCounts = <String, int>{};
      final studentsByCourse = <String, Set<String>>{};
      for (final enrollment in enrollments) {
        final courseId = enrollment['course_id']?.toString();
        final studentId = enrollment['student_id']?.toString();
        if (courseId == null || studentId == null) continue;
        final students = studentsByCourse.putIfAbsent(
          courseId,
          () => <String>{},
        );
        students.add(studentId);
      }
      for (final entry in studentsByCourse.entries) {
        enrollmentCounts[entry.key] = entry.value.length;
      }

      final courseByMaterial = <String, String>{};
      final materialsByCourse = <String, Set<String>>{};
      for (final material in materials) {
        final courseId = material['course_id']?.toString();
        final materialId = material['id']?.toString();
        if (courseId == null || materialId == null) continue;
        courseByMaterial[materialId] = courseId;
        materialsByCourse
            .putIfAbsent(courseId, () => <String>{})
            .add(materialId);
      }

      final courseByQuiz = <String, String>{};
      final quizzesByCourse = <String, Set<String>>{};
      for (final quiz in quizzes) {
        if (quiz['status'] != 'published') continue;
        final courseId = quiz['course_id']?.toString();
        final quizId = quiz['id']?.toString();
        if (courseId == null || quizId == null) continue;
        courseByQuiz[quizId] = courseId;
        quizzesByCourse.putIfAbsent(courseId, () => <String>{}).add(quizId);
      }

      final completedAssignmentsByCourse = <String, Set<String>>{};
      for (final progress in materialProgress) {
        if (progress['completed'] != true) continue;
        final materialId = progress['material_id']?.toString();
        final studentId = progress['user_id']?.toString();
        final courseId = materialId == null
            ? null
            : courseByMaterial[materialId];
        if (courseId == null ||
            studentId == null ||
            studentsByCourse[courseId]?.contains(studentId) != true) {
          continue;
        }
        completedAssignmentsByCourse
            .putIfAbsent(courseId, () => <String>{})
            .add('material:$materialId:$studentId');
      }
      for (final attempt in quizAttempts) {
        if (attempt['completed'] != true) continue;
        final quizId = attempt['quiz_id']?.toString();
        final studentId = attempt['user_id']?.toString();
        final courseId = quizId == null ? null : courseByQuiz[quizId];
        if (courseId == null ||
            studentId == null ||
            studentsByCourse[courseId]?.contains(studentId) != true) {
          continue;
        }
        completedAssignmentsByCourse
            .putIfAbsent(courseId, () => <String>{})
            .add('quiz:$quizId:$studentId');
      }

      for (final course in courses) {
        final courseId = course['id']?.toString();
        final studentCount = courseId == null
            ? 0
            : enrollmentCounts[courseId] ?? 0;
        final taskCount = courseId == null
            ? 0
            : (materialsByCourse[courseId]?.length ?? 0) +
                  (quizzesByCourse[courseId]?.length ?? 0);
        final totalAssignments = studentCount * taskCount;
        final completedAssignments =
            completedAssignmentsByCourse[courseId]?.length ?? 0;
        course['student_count'] = studentCount;
        course['completion_rate'] = totalAssignments == 0
            ? 0
            : (completedAssignments / totalAssignments * 100).round().clamp(
                0,
                100,
              );
      }

      // Nama guru (opsional, hanya kalau tabel profiles bisa dibaca)
      final names = <String, String>{};
      try {
        final pd = await _db.from(_tProfiles).select('*');
        for (final p in List<Map<String, dynamic>>.from(pd as List)) {
          final id = p['id'];
          if (id == null) continue;
          names['$id'] = (_pick(p, ['full_name', 'name', 'nama']) ?? '-')
              .toString();
        }
      } catch (e) {
        debugPrint('[CourseList] profiles gagal: $e');
      }

      if (courses.isNotEmpty) {
        debugPrint('[CourseList] kolom course: ${courses.first.keys.toList()}');
      }

      if (!mounted) return;
      setState(() {
        _courses = courses;
        _teacherNames = names;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[CourseList] query gagal: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final ok = await showConfirmDanger(
      context,
      title: 'Hapus Course?',
      message: '${_title(c)} akan dihapus dari platform.',
    );
    if (!ok || !mounted) return;

    final key = _idKey(c);
    if (key == null) {
      _snack('Gagal menghapus: kolom ID course tidak ditemukan.');
      return;
    }

    try {
      final courseId = c[key].toString();
      if (courseId.isEmpty) {
        _snack('ID course tidak valid.');
        return;
      }
      await _db.rpc('admin_delete_course', params: {'p_course_id': courseId});
    } catch (e) {
      debugPrint('[CourseList] hapus gagal: $e');
      if (mounted) _snack('Gagal menghapus course: $e');
      return;
    }

    if (!mounted) return;
    setState(() => _courses.removeWhere((x) => identical(x, c)));

    await showSuccessDialog(context, 'Course berhasil dihapus!');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openCourseForm({Map<String, dynamic>? course}) async {
    try {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          settings: RouteSettings(
            name: RouteNames.adminCourseForm,
            arguments: course,
          ),
          builder: (_) => const AdminCourseFormPage(),
        ),
      );
      if (changed == true && mounted) _load();
    } catch (e) {
      debugPrint('[CourseList] gagal membuka form course: $e');
      if (mounted) _snack('Halaman course tidak dapat dibuka: $e');
    }
  }

  Future<void> _openCourseDetail(Map<String, dynamic> course) async {
    final key = _idKey(course);
    if (key == null || course[key].toString().isEmpty) {
      _snack('ID course tidak valid.');
      return;
    }

    try {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          settings: RouteSettings(
            name: RouteNames.adminCourseDetail,
            arguments: course[key].toString(),
          ),
          builder: (_) => const AdminCourseDetailPage(),
        ),
      );
      if (changed == true && mounted) _load();
    } catch (e) {
      debugPrint('[CourseList] gagal membuka detail course: $e');
      if (mounted) _snack('Detail course tidak dapat dibuka: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final items = _courses.where((c) => _title(c).toLowerCase().contains(q));

    return EduScaffold(
      bottom: const EduBottomNav(role: 'admin', current: 2),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          PageTitle('Manajemen Course', onAdd: () => _openCourseForm()),
          const SizedBox(height: 14),
          SearchBox(
            hint: 'Cari Course',
            pill: true,
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  SelectableText(
                    'Gagal memuat course:\n$_error',
                    style: const TextStyle(fontSize: 10, color: Colors.red),
                  ),
                  TextButton(onPressed: _load, child: const Text('Coba lagi')),
                ],
              ),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Belum ada course.')),
            )
          else
            for (final c in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EduCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _title(c),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Pill(
                            _active(c) ? 'Aktif' : 'Nonaktif',
                            kind: _active(c)
                                ? PillKind.active
                                : PillKind.inactive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_teacher(c)} • ${_subject(c)}',
                        style: const TextStyle(fontSize: 8.5),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          text: '${_students(c)} Siswa  ',
                          style: const TextStyle(fontSize: 8.5),
                          children: [
                            TextSpan(
                              text: '${_percent(c)}% Selesai',
                              style: const TextStyle(color: Ui.greenDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SoftBtn.edit(
                              onTap: () => _openCourseForm(course: c),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SoftBtn.delete(onTap: () => _delete(c)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SoftBtn(
                              label: 'Detail',
                              icon: Icons.visibility_outlined,
                              bg: Ui.greenSoft,
                              fg: Ui.greenDark,
                              onTap: () => _openCourseDetail(c),
                            ),
                          ),
                        ],
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
