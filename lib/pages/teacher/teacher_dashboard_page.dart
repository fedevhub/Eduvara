import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _CourseItem {
  final String id;
  final String title;
  final int studentCount;
  final double completion; // 0..1
  const _CourseItem({
    required this.id,
    required this.title,
    required this.studentCount,
    required this.completion,
  });
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final _db = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  String _teacherName = '-';
  int _totalCourses = 0;
  int _totalStudents = 0;
  double? _avgCompletion; // 0..1, null = belum ada data
  double? _avgQuizScore; // null = belum ada data
  bool _hasUnread = false;
  List<_CourseItem> _activeCourses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _db.auth.currentUser;
      if (user == null) throw 'Sesi login tidak ditemukan';

      // 1. Profil guru
      final profile = await _db
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      // 2. Kursus milik guru
     final courseRows = await _db
    .from('courses')
    .select('id, title, status')
    .eq('teacher_id', user.id);
      final courses = List<Map<String, dynamic>>.from(courseRows);
      final courseIds = courses.map((c) => c['id']).toList();

      // 3. Siswa per kursus
      final studentsByCourse = <String, Set<String>>{};
      final allStudents = <String>{};
      if (courseIds.isNotEmpty) {
        final enrollRows = await _db
            .from('enrollments')
            .select('course_id, student_id')
            .inFilter('course_id', courseIds);
        for (final e in List<Map<String, dynamic>>.from(enrollRows)) {
          final cid = e['course_id'].toString();
          final sid = e['student_id'].toString();
          studentsByCourse.putIfAbsent(cid, () => <String>{}).add(sid);
          allStudents.add(sid);
        }
      }

      // 4. Progress (opsional: kolom enrollments.progress, 0-100)
      final progressByCourse = <String, List<double>>{};
      if (courseIds.isNotEmpty) {
        try {
          final rows = await _db
              .from('enrollments')
              .select('course_id, progress')
              .inFilter('course_id', courseIds);
          for (final r in List<Map<String, dynamic>>.from(rows)) {
            final p = (r['progress'] as num?)?.toDouble();
            if (p == null) continue;
            progressByCourse
                .putIfAbsent(r['course_id'].toString(), () => [])
                .add(p / 100);
          }
        } catch (_) {
          // kolom/tabel belum ada -> dianggap belum ada data
        }
      }

      // 5. Nilai kuis (opsional: tabel quiz_results, kolom course_id & score)
      double? avgQuiz;
      if (courseIds.isNotEmpty) {
        try {
          final rows = await _db
              .from('quiz_results')
              .select('score')
              .inFilter('course_id', courseIds);
          final scores = List<Map<String, dynamic>>.from(rows)
              .map((r) => (r['score'] as num?)?.toDouble())
              .whereType<double>()
              .toList();
          if (scores.isNotEmpty) {
            avgQuiz = scores.reduce((a, b) => a + b) / scores.length;
          }
        } catch (_) {}
      }

      // 6. Notifikasi belum dibaca (opsional: tabel notifications)
      bool unread = false;
      try {
        final rows = await _db
            .from('notifications')
            .select('id')
            .eq('user_id', user.id)
            .eq('is_read', false)
            .limit(1);
        unread = List.from(rows).isNotEmpty;
      } catch (_) {}

      double avgOf(List<double> v) =>
          v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

      final active = courses
          .where((c) => c['status'] == 'active')
          .map((c) {
            final id = c['id'].toString();
            return _CourseItem(
              id: id,
              title: (c['title'] ?? '-').toString(),
              studentCount: studentsByCourse[id]?.length ?? 0,
              completion: avgOf(progressByCourse[id] ?? const []),
            );
          })
          .toList();

      final allProgress = progressByCourse.values.expand((e) => e).toList();

      if (!mounted) return;
      setState(() {
        _teacherName = (profile?['full_name'] ?? '-').toString();
        _totalCourses = courses.length;
        _totalStudents = allStudents.length;
        _avgCompletion = allProgress.isEmpty ? null : avgOf(allProgress);
        _avgQuizScore = avgQuiz;
        _hasUnread = unread;
        _activeCourses = active;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Pindah page, lalu refresh dashboard saat kembali
  Future<void> _go(String route, {Object? arguments}) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'teacher', current: 0),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _buildError()
        else ...[
          _buildStats(),
          const SizedBox(height: 16),
          const Text(
            'Kursus Aktif',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (_activeCourses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada kursus aktif',
                style: TextStyle(fontSize: 11),
              ),
            )
          else
            for (final c in _activeCourses) ...[
              _ActiveCourse(
                title: c.title,
                info:
                    '${c.studentCount} siswa • ${(c.completion * 100).round()}% selesai',
                value: c.completion,
                onTap: () => _go(
                  RouteNames.teacherCourseDetail,
                  arguments: c.id, // id kursus dikirim ke halaman detail
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ],
    ),
  );

  Widget _buildHeader() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel Teacher', style: TextStyle(fontSize: 11)),
            Text(
              _teacherName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      GestureDetector(
        onTap: () => _go(RouteNames.teacherNotifications),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none, size: 24),
            if (_hasUnread)
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
  );

  Widget _buildStats() => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: StatBox(
              value: '$_totalCourses',
              label: 'Total Kursus',
              icon: Icons.menu_book_outlined,
              tall: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatBox(
              value: '$_totalStudents',
              label: 'Total Siswa',
              icon: Icons.groups_outlined,
              tall: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: StatBox(
              value: _avgCompletion == null
                  ? '-'
                  : '${(_avgCompletion! * 100).round()}%',
              label: 'Avg Completion',
              icon: Icons.bar_chart,
              tall: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatBox(
              value: _avgQuizScore == null
                  ? '-'
                  : _avgQuizScore!.round().toString(),
              label: 'Avg Quiz Score',
              icon: Icons.gps_fixed,
              tall: true,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildError() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Column(
        children: [
          Text(
            'Gagal memuat data\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Coba lagi')),
        ],
      ),
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
        ProgressLine(value: value.clamp(0.0, 1.0), height: 5),
      ],
    ),
  );
}