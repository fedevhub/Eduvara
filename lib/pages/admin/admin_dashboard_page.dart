import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';

class _T {
  static const profiles = 'profiles';
  static const courses = 'courses';
  static const quizzes = 'quizzes';
  static const activities = 'activity_logs';
}

class _CourseRate {
  final String title;
  final int percent;
  const _CourseRate(this.title, this.percent);
}

class _ActivityItem {
  final String title;
  final DateTime? createdAt;
  final String entity;
  final String? courseId;
  const _ActivityItem(this.title, this.createdAt, this.entity, this.courseId);
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final SupabaseClient _db = Supabase.instance.client;

  String _adminName = 'Admin';
  int _totalSiswa = 0;
  int _totalGuru = 0;
  int _totalKursus = 0;
  int _totalQuiz = 0;
  int _unreadNotifications = 0;
  List<_CourseRate> _rates = [];
  List<_ActivityItem> _activities = [];

  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  final List<String> _errors = [];

  bool _isRole(Map<String, dynamic> p, List<String> names) =>
      names.contains('${p['role']}'.toLowerCase().trim());

  Future<List<Map<String, dynamic>>> _fetch(
    String table,
    String columns, {
    String? orderBy,
    int? limit,
  }) async {
    try {
      final base = _db.from(table).select(columns);
      final ordered = orderBy == null
          ? base
          : base.order(orderBy, ascending: false);
      final data = limit == null ? await ordered : await ordered.limit(limit);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('[AdminDashboard] query "$table" gagal: $e');
      _errors.add('$table: $e');
      return [];
    }
  }

  /// Ambil nilai dari beberapa kemungkinan nama kolom.
  dynamic _pick(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      if (row.containsKey(k) && row[k] != null) return row[k];
    }
    return null;
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    _errors.clear();

    final results = await Future.wait([
      _fetch(_T.profiles, '*'),
      _fetch(_T.courses, '*'),
      _fetch(_T.quizzes, 'id, course_id, status'),
      _fetch('enrollments', 'course_id, student_id'),
      _fetch('materials', 'id, course_id'),
      _fetch('material_progress', 'user_id, material_id, completed'),
      _fetch('quiz_attempts', 'user_id, quiz_id, completed'),
      _fetch(
        _T.activities,
        'id, actor_role, actor_name, action, entity, entity_id, entity_name, is_read, created_at',
        orderBy: 'created_at',
        limit: 300,
      ),
    ]);

    if (!mounted) return;

    final profiles = results[0];
    final courses = results[1];
    final quizzes = results[2];
    final enrollments = results[3];
    final materials = results[4];
    final materialProgress = results[5];
    final quizAttempts = results[6];
    final activities = results[7];

    // Debug: lihat kolom asli tiap tabel di console
    for (final entry in {
      'profiles': profiles,
      'course': courses,
      'quizzes': quizzes,
    }.entries) {
      if (entry.value.isNotEmpty) {
        debugPrint(
          '[AdminDashboard] kolom ${entry.key}: '
          '${entry.value.first.keys.toList()}',
        );
      }
    }

    // Nama admin yang sedang login
    final uid = _db.auth.currentUser?.id;
    final me = profiles.where((p) => p['id'] == uid).toList();
    final name = me.isNotEmpty
        ? _pick(me.first, ['full_name', 'name', 'nama'])?.toString()
        : null;
    var unreadNotifications = 0;
    if (uid != null) {
      try {
        final notifications = await _db
            .from('notifications')
            .select('id')
            .eq('user_id', uid)
            .eq('is_read', false);
        unreadNotifications = notifications.length;
      } catch (error) {
        debugPrint('[AdminDashboard] gagal memuat unread notification: $error');
        _errors.add('notifications: $error');
      }
    }

    final enrollmentsByCourse = <String, Set<String>>{};
    for (final enrollment in enrollments) {
      enrollmentsByCourse
          .putIfAbsent(enrollment['course_id'].toString(), () => <String>{})
          .add(enrollment['student_id'].toString());
    }

    final materialsByCourse = <String, Set<String>>{};
    final courseByMaterial = <String, String>{};
    for (final material in materials) {
      final courseId = material['course_id'].toString();
      final materialId = material['id'].toString();
      materialsByCourse.putIfAbsent(courseId, () => <String>{}).add(materialId);
      courseByMaterial[materialId] = courseId;
    }

    final publishedQuizzesByCourse = <String, Set<String>>{};
    final courseByQuiz = <String, String>{};
    for (final quiz in quizzes) {
      if (quiz['status'] != 'published') continue;
      final courseId = quiz['course_id'].toString();
      final quizId = quiz['id'].toString();
      publishedQuizzesByCourse
          .putIfAbsent(courseId, () => <String>{})
          .add(quizId);
      courseByQuiz[quizId] = courseId;
    }

    final completedByCourse = <String, int>{};
    for (final progress in materialProgress) {
      if (progress['completed'] != true) continue;
      final courseId = courseByMaterial[progress['material_id'].toString()];
      final studentIds = courseId == null
          ? null
          : enrollmentsByCourse[courseId];
      if (courseId != null &&
          studentIds?.contains(progress['user_id'].toString()) == true) {
        completedByCourse.update(
          courseId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final completedQuizAssignments = <String>{};
    for (final attempt in quizAttempts) {
      if (attempt['completed'] != true) continue;
      final quizId = attempt['quiz_id'].toString();
      final courseId = courseByQuiz[quizId];
      final studentId = attempt['user_id'].toString();
      if (courseId == null ||
          enrollmentsByCourse[courseId]?.contains(studentId) != true) {
        continue;
      }
      if (completedQuizAssignments.add('$courseId:$quizId:$studentId')) {
        completedByCourse.update(
          courseId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final rates = courses.map((course) {
      final courseId = course['id'].toString();
      final studentCount = enrollmentsByCourse[courseId]?.length ?? 0;
      final taskCount =
          (materialsByCourse[courseId]?.length ?? 0) +
          (publishedQuizzesByCourse[courseId]?.length ?? 0);
      final totalAssignments = studentCount * taskCount;
      final percent = totalAssignments == 0
          ? 0
          : ((completedByCourse[courseId] ?? 0) / totalAssignments * 100)
                .round();
      return _CourseRate(
        (_pick(course, ['title', 'name', 'nama', 'judul']) ?? '-').toString(),
        percent.clamp(0, 100).toInt(),
      );
    }).toList();

    DateTime? dateOf(Map<String, dynamic> n) => DateTime.tryParse(
      '${_pick(n, ['created_at', 'date', 'time', 'timestamp'])}',
    )?.toLocal();
    final userActivities =
        activities
            .where(
              (activity) =>
                  ['teacher', 'student'].contains(activity['actor_role']),
            )
            .toList()
          ..sort((a, b) {
            final aDate = dateOf(a);
            final bDate = dateOf(b);
            if (aDate == null) return bDate == null ? 0 : 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

    setState(() {
      _adminName = (name == null || name.isEmpty) ? 'Admin' : name;
      _totalSiswa = profiles
          .where((p) => _isRole(p, ['student', 'siswa']))
          .length;
      _totalGuru = profiles
          .where((p) => _isRole(p, ['teacher', 'guru']))
          .length;
      _totalKursus = courses.length;
      _totalQuiz = quizzes.length;
      _unreadNotifications = unreadNotifications;
      _rates = rates;
      _activities = userActivities.take(3).map((activity) {
        final action = (activity['action'] ?? '').toString();
        final entity = (activity['entity'] ?? 'course').toString();
        final entityLabel = switch (entity) {
          'material' => 'materi',
          'quiz' => 'quiz',
          'user' => 'akun',
          'course' => 'course',
          _ => 'course',
        };
        final entityName = (activity['entity_name'] ?? entityLabel).toString();
        final actorName = (activity['actor_name'] ?? 'Admin').toString();
        final verb = switch (action) {
          'insert' => 'menambahkan',
          'update' => 'memperbarui',
          'delete' => 'menghapus',
          'complete' => 'menyelesaikan',
          'submit' => 'mengumpulkan',
          _ => 'mengubah',
        };
        return _ActivityItem(
          '$actorName $verb $entityLabel "$entityName"',
          dateOf(activity),
          entity,
          activity['entity_id']?.toString(),
        );
      }).toList();
      _loading = false;
      _error = false;
    });
  }

  /// Buka page lain, lalu refresh dashboard saat kembali
  /// supaya angka & notifikasi selalu sinkron.
  Future<void> _go(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) _loadDashboard();
  }

  void _openNotifications() => _go(RouteNames.adminNotifications);

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}/${time.year}';
  }

  Widget _tappable(Widget child, String route) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _go(route),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return EduScaffold(
      bottom: const EduBottomNav(role: 'admin', current: 0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Panel Admin', style: TextStyle(fontSize: 11)),
                    Text(
                      _adminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _NotificationButton(
                count: _unreadNotifications,
                onTap: _openNotifications,
              ),
              const SizedBox(width: 10),
              DarkAvatar(name: _adminName, size: 34),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    const Text('Data gagal dimuat.'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadDashboard,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (_errors.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  'Error Supabase:\n${_errors.join('\n')}',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _tappable(
                    StatBox(
                      value: '$_totalSiswa',
                      label: 'Total Siswa',
                      icon: Icons.groups_outlined,
                      tall: true,
                    ),
                    RouteNames.adminUsers,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tappable(
                    StatBox(
                      value: '$_totalGuru',
                      label: 'Total Guru',
                      icon: Icons.co_present_outlined,
                      tall: true,
                    ),
                    RouteNames.adminUsers,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _tappable(
                    StatBox(
                      value: '$_totalKursus',
                      label: 'Total Kursus',
                      icon: Icons.menu_book_outlined,
                      tall: true,
                    ),
                    RouteNames.adminCourses,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tappable(
                    StatBox(
                      value: '$_totalQuiz',
                      label: 'Total Quiz',
                      icon: Icons.fact_check_outlined,
                      tall: true,
                    ),
                    RouteNames.adminQuizzes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            EduCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Completion Rate',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (_rates.isEmpty)
                    const Text('Belum ada data kursus.')
                  else
                    for (final rate in _rates) _Rate(rate.title, rate.percent),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (_activities.isEmpty)
              const Text('Belum ada aktivitas.')
            else
              for (final item in _activities)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _go(RouteNames.adminCourses),
                  child: _Activity(item.title, _formatTime(item.createdAt)),
                ),
          ],
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 27,
            color: Ui.navy,
          ),
          if (count > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(3),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  final String label;
  final int value;

  const _Rate(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 9))),
              Text(
                '$value%',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Ui.greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ProgressLine(value: (value / 100).clamp(0.0, 1.0), height: 5),
        ],
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  final String title;
  final String time;

  const _Activity(this.title, this.time);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EduCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Ui.navy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 8, color: Ui.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
