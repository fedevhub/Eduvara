import 'dart:async';

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
  final String title;
  final int studentCount;
  final double completion; // 0..1
  const _CourseItem({
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
  int _unreadNotificationCount = 0;
  List<_CourseItem> _activeCourses = [];
  RealtimeChannel? _notificationChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _watchNotifications();
  }

  @override
  void dispose() {
    final channel = _notificationChannel;
    if (channel != null) unawaited(_db.removeChannel(channel));
    super.dispose();
  }

  void _watchNotifications() {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    _notificationChannel = _db
        .channel('teacher-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _refreshUnreadNotificationCount(),
        )
        .subscribe();
  }

  Future<void> _refreshUnreadNotificationCount() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final rows = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      if (!mounted) return;
      setState(() => _unreadNotificationCount = rows.length);
    } catch (e) {
      debugPrint('[TeacherDashboard] Gagal memperbarui jumlah notifikasi: $e');
    }
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
      final courseIds = courses.map((c) => c['id'].toString()).toList();

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

      // 4. Progress dihitung dari materi yang ditandai selesai siswa.
      final materialCountByCourse = <String, int>{};
      final courseByMaterial = <String, String>{};
      if (courseIds.isNotEmpty) {
        final materialRows = await _db
            .from('materials')
            .select('id, course_id')
            .inFilter('course_id', courseIds);
        for (final material in materialRows) {
          final courseId = material['course_id'].toString();
          materialCountByCourse[courseId] =
              (materialCountByCourse[courseId] ?? 0) + 1;
          courseByMaterial[material['id'].toString()] = courseId;
        }
      }

      final completedByCourse = <String, int>{};
      if (courseByMaterial.isNotEmpty) {
        final progressRows = await _db
            .from('material_progress')
            .select('material_id')
            .eq('completed', true)
            .inFilter('material_id', courseByMaterial.keys.toList());
        for (final progress in progressRows) {
          final courseId = courseByMaterial[progress['material_id'].toString()];
          if (courseId != null) {
            completedByCourse[courseId] =
                (completedByCourse[courseId] ?? 0) + 1;
          }
        }
      }

      final completionByCourse = <String, double>{};
      for (final course in courses) {
        final id = course['id'].toString();
        final studentCount = studentsByCourse[id]?.length ?? 0;
        final denominator = (materialCountByCourse[id] ?? 0) * studentCount;
        if (denominator > 0) {
          completionByCourse[id] = (completedByCourse[id] ?? 0) / denominator;
        }
      }

      // 5. Nilai diambil dari percobaan quiz yang disimpan siswa.
      double? avgQuiz;
      if (courseIds.isNotEmpty) {
        final quizzes = await _db
            .from('quizzes')
            .select('id')
            .inFilter('course_id', courseIds);
        final quizIds = quizzes.map((quiz) => quiz['id'].toString()).toList();
        if (quizIds.isNotEmpty) {
          final attempts = await _db
              .from('quiz_attempts')
              .select('score')
              .inFilter('quiz_id', quizIds)
              .eq('completed', true);
          final scores = List<Map<String, dynamic>>.from(attempts)
              .map((attempt) => (attempt['score'] as num?)?.toDouble())
              .whereType<double>()
              .toList();
          if (scores.isNotEmpty) {
            avgQuiz = scores.reduce((a, b) => a + b) / scores.length;
          }
        }
      }

      // 6. Notifikasi pribadi dan pengumuman umum.
      final notificationRows = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);
      final unreadCount = notificationRows.length;

      final active = courses.where((c) => c['status'] == 'active').map((c) {
        final id = c['id'].toString();
        return _CourseItem(
          title: (c['title'] ?? '-').toString(),
          studentCount: studentsByCourse[id]?.length ?? 0,
          completion: completionByCourse[id] ?? 0,
        );
      }).toList();

      final allProgress = completionByCourse.values.toList();
      final avgCompletion = allProgress.isEmpty
          ? null
          : allProgress.reduce((a, b) => a + b) / allProgress.length;

      if (!mounted) return;
      setState(() {
        _teacherName = (profile?['full_name'] ?? '-').toString();
        _totalCourses = courses.length;
        _totalStudents = allStudents.length;
        _avgCompletion = avgCompletion;
        _avgQuizScore = avgQuiz;
        _unreadNotificationCount = unreadCount;
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
                studentCount: c.studentCount,
                value: c.completion,
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
            const Text('Dashboard Teacher', style: TextStyle(fontSize: 11)),
            Text(
              _teacherName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
            if (_unreadNotificationCount > 0)
              Positioned(
                right: -8,
                top: -7,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Ui.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Ui.bg, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _unreadNotificationCount > 99
                        ? '99+'
                        : '$_unreadNotificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      DarkAvatar(name: _teacherName, size: 34),
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
  final int studentCount;
  final double value;
  const _ActiveCourse({
    required this.title,
    required this.studentCount,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => EduCard(
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
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 8.5),
                      children: [
                        TextSpan(text: '$studentCount siswa • '),
                        TextSpan(
                          text: '${(value * 100).round()}%',
                          style: const TextStyle(
                            color: Ui.greenDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: ' selesai',
                          style: TextStyle(color: Ui.greenDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressLine(value: value.clamp(0.0, 1.0), height: 5),
      ],
    ),
  );
}
