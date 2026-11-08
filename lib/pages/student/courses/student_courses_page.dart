import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/course_model.dart';
import '../../../repositories/course_repository.dart';

enum _St { done, running, locked }

class _CourseRow {
  final Course course;
  final _St status;
  final int pct;
  const _CourseRow(this.course, this.status, this.pct);
}

class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});
  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  int filter = 0;
  String query = '';
  final CourseRepository _repository = CourseRepository();
  final _db = Supabase.instance.client;
  late Future<List<_CourseRow>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<_CourseRow>> _load() async {
    final courses = await _repository.getCourses();
    if (courses.isEmpty) return [];

    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw 'Sesi login berakhir, silakan login ulang';

    final courseIds = courses.map((c) => c.id.toString()).toList();

    // total materi per course
    List<Map<String, dynamic>> materials = const [];
    try {
      materials = List<Map<String, dynamic>>.from(
        await _db
            .from('materials')
            .select('id, course_id')
            .inFilter('course_id', courseIds),
      );
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST205') rethrow;
    }

    final totalByCourse = <String, int>{};
    final courseByMaterial = <String, String>{};
    for (final m in materials) {
      final cid = m['course_id'].toString();
      totalByCourse[cid] = (totalByCourse[cid] ?? 0) + 1;
      courseByMaterial[m['id'].toString()] = cid;
    }

    List<Map<String, dynamic>> quizzes = const [];
    try {
      quizzes = List<Map<String, dynamic>>.from(
        await _db
            .from('quizzes')
            .select('id, course_id')
            .inFilter('course_id', courseIds)
            .eq('status', 'published'),
      );
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST205') rethrow;
    }
    final totalQuizzesByCourse = <String, int>{};
    final courseByQuiz = <String, String>{};
    for (final quiz in quizzes) {
      final courseId = quiz['course_id'].toString();
      totalQuizzesByCourse[courseId] =
          (totalQuizzesByCourse[courseId] ?? 0) + 1;
      courseByQuiz[quiz['id'].toString()] = courseId;
    }
    final doneQuizByCourse = <String, int>{};
    if (courseByQuiz.isNotEmpty) {
      final attempts = await _db
          .from('quiz_attempts')
          .select('quiz_id')
          .eq('user_id', uid)
          .eq('completed', true)
          .inFilter('quiz_id', courseByQuiz.keys.toList());
      for (final attempt in attempts) {
        final courseId = courseByQuiz[attempt['quiz_id'].toString()];
        if (courseId != null) {
          doneQuizByCourse[courseId] = (doneQuizByCourse[courseId] ?? 0) + 1;
        }
      }
    }

    final doneByCourse = <String, int>{};
    if (courseByMaterial.isNotEmpty) {
      final progress = await _db
          .from('material_progress')
          .select('material_id')
          .eq('user_id', uid)
          .eq('completed', true)
          .inFilter('material_id', courseByMaterial.keys.toList());
      for (final p in progress) {
        final cid = courseByMaterial[p['material_id'].toString()];
        if (cid != null) doneByCourse[cid] = (doneByCourse[cid] ?? 0) + 1;
      }
    }

    // hitung status: terkunci jika course sebelumnya belum selesai
    final rows = <_CourseRow>[];
    var previousDone = true;
    for (final c in courses) {
      final cid = c.id.toString();
      final total =
          (totalByCourse[cid] ?? 0) + (totalQuizzesByCourse[cid] ?? 0);
      final done = (doneByCourse[cid] ?? 0) + (doneQuizByCourse[cid] ?? 0);
      final pct = total == 0 ? 0 : ((done / total) * 100).round();
      final isDone = total > 0 && done >= total;

      final st = !previousDone ? _St.locked : (isDone ? _St.done : _St.running);

      rows.add(_CourseRow(c, st, pct));
      previousDone = isDone;
    }
    return rows;
  }

  void _reload() {
    final next = _load();
    if (!mounted) return;
    setState(() {
      _rows = next;
    });
  }

  bool _match(_St s) => switch (filter) {
    1 => s == _St.done,
    2 => s == _St.running,
    3 => s == _St.locked,
    _ => true,
  };

  Widget _card(Course course, _St st, int pct) {
    final color = switch (st) {
      _St.done => Ui.green,
      _St.running => Ui.blue,
      _St.locked => Ui.orange,
    };
    final card = EduCard(
      borderColor: st == _St.locked ? null : color,
      padding: const EdgeInsets.all(12),
      onTap: st == _St.locked
          ? null
          : () async {
              await Navigator.pushNamed(
                context,
                RouteNames.studentCourseDetail,
                arguments: {'course_id': course.id},
              );
              // refresh progress setelah kembali dari detail
              if (mounted) _reload();
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Pill(
                switch (st) {
                  _St.done => 'Selesai',
                  _St.running => 'Berjalan',
                  _St.locked => 'Terkunci',
                },
                kind: switch (st) {
                  _St.done => PillKind.done,
                  _St.running => PillKind.running,
                  _St.locked => PillKind.locked,
                },
              ),
            ],
          ),
          Text(
            '${course.teacher} • ${course.description}',
            style: const TextStyle(fontSize: 8.5),
          ),
          if (st != _St.locked) ...[
            const SizedBox(height: 8),
            Text(
              '$pct% ${st == _St.done ? 'Selesai' : 'Berjalan'}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            ProgressLine(value: pct / 100, color: color),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: st == _St.locked
          ? LockedCard(text: 'Selesaikan Course Sebelumnya', child: card)
          : card,
    );
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'student', current: 1),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text(
          'Manajemen Course',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SearchBox(
          hint: 'Cari Course',
          pill: true,
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 10),
        FilterChips(
          labels: const ['Semua', 'Selesai', 'Berjalan', 'Terkunci'],
          index: filter,
          onChanged: (i) => setState(() => filter = i),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<_CourseRow>>(
          future: _rows,
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
                  const Text('Course belum dapat dimuat.'),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }
            final rows = snapshot.data ?? [];
            final visible = rows
                .where(
                  (r) =>
                      _match(r.status) &&
                      r.course.title.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
            if (visible.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Course tidak ditemukan.'),
              );
            }
            return Column(
              children: [
                for (final r in visible) _card(r.course, r.status, r.pct),
              ],
            );
          },
        ),
      ],
    ),
  );
}