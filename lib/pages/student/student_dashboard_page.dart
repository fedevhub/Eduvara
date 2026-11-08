import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';
import '../../models/course_model.dart';
import '../../repositories/course_repository.dart';

enum _St { done, running, locked }

class _CourseInfo {
  final Course course;
  final _St status;
  final int total;
  final int pct;
  const _CourseInfo(this.course, this.status, this.total, this.pct);
}

class _DashData {
  final String name;
  final List<_CourseInfo> courses;
  const _DashData(this.name, this.courses);

  int count(_St s) => courses.where((c) => c.status == s).length;
  _CourseInfo? first(_St s) {
    for (final c in courses) {
      if (c.status == s) return c;
    }
    return null;
  }
}

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final _db = Supabase.instance.client;
  final _repository = CourseRepository();
  late Future<_DashData> _data;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  void _reload() {
    final next = _load();
    if (!mounted) return;
    setState(() {
      _data = next;
    });
  }

  bool _isMissingTableError(PostgrestException e) =>
      e.code == 'PGRST205' ||
      e.message.toLowerCase().contains('could not find the table');

  Future<_DashData> _load() async {
    final user = _db.auth.currentUser;
    if (user == null) throw 'Sesi login berakhir, silakan login ulang';

    // nama siswa
    Map<String, dynamic>? profile;
    try {
      profile = await _db
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
    } on PostgrestException catch (e) {
      if (!_isMissingTableError(e)) rethrow;
    }
    final name =
        (profile?['full_name'] ??
                user.userMetadata?['full_name'] ??
                user.email ??
                '-')
            .toString();

    try {
      final rows = await _db
          .from('notifications')
          .select('id')
          .or('user_id.eq.${user.id},user_id.is.null')
          .eq('is_read', false)
          .limit(99);
      _unreadNotifications = List<Map<String, dynamic>>.from(rows).length;
    } on PostgrestException catch (e) {
      if (!_isMissingTableError(e)) {
        debugPrint('[StudentDashboard] gagal memuat count notifikasi: $e');
      }
      _unreadNotifications = 0;
    }

    final courses = await _repository.getCourses();
    if (courses.isEmpty) return _DashData(name, const []);

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

    List<Map<String, dynamic>> quizzes = const [];
    try {
      quizzes = List<Map<String, dynamic>>.from(
        await _db
            .from('quizzes')
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

    final totalQuizByCourse = <String, int>{};
    final quizById = <String, String>{};
    for (final q in quizzes) {
      final cid = q['course_id'].toString();
      totalQuizByCourse[cid] = (totalQuizByCourse[cid] ?? 0) + 1;
      quizById[q['id'].toString()] = cid;
    }

    // materi yang sudah diselesaikan siswa
    final doneByCourse = <String, int>{};
    if (courseByMaterial.isNotEmpty) {
      final progress = await _db
          .from('material_progress')
          .select('material_id')
          .eq('user_id', user.id)
          .eq('completed', true)
          .inFilter('material_id', courseByMaterial.keys.toList());
      for (final p in progress) {
        final cid = courseByMaterial[p['material_id'].toString()];
        if (cid != null) doneByCourse[cid] = (doneByCourse[cid] ?? 0) + 1;
      }
    }

    final doneQuizByCourse = <String, int>{};
    if (quizById.isNotEmpty) {
      final attempts = await _db
          .from('quiz_attempts')
          .select('quiz_id')
          .eq('user_id', user.id)
          .eq('completed', true)
          .inFilter('quiz_id', quizById.keys.toList());
      for (final a in attempts) {
        final cid = quizById[a['quiz_id'].toString()];
        if (cid != null) {
          doneQuizByCourse[cid] = (doneQuizByCourse[cid] ?? 0) + 1;
        }
      }
    }

    // status: terkunci jika course sebelumnya belum selesai
    final infos = <_CourseInfo>[];
    var previousDone = true;
    for (final c in courses) {
      final cid = c.id.toString();
      final total = totalByCourse[cid] ?? 0;
      final done = doneByCourse[cid] ?? 0;
      final totalQuiz = totalQuizByCourse[cid] ?? 0;
      final doneQuiz = doneQuizByCourse[cid] ?? 0;
      final pct = total == 0 ? 0 : ((done / total) * 100).round();
      final quizDone = totalQuiz > 0 && doneQuiz >= totalQuiz;
      final isDone = (total > 0 && done >= total) || quizDone;

      final st = !previousDone ? _St.locked : (isDone ? _St.done : _St.running);

      infos.add(_CourseInfo(c, st, total, pct));
      previousDone = isDone;
    }
    return _DashData(name, infos);
  }

  Widget _metric(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Ui.greenDark,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 8, color: Ui.muted)),
        ],
      ),
    ),
  );

  Widget _runningCard(_CourseInfo info) => EduCard(
    borderColor: Ui.blue,
    padding: const EdgeInsets.all(12),
    onTap: () async {
      await Navigator.pushNamed(
        context,
        RouteNames.studentCourseDetail,
        arguments: {'course_id': info.course.id},
      );
      // refresh progress setelah kembali dari detail
      if (mounted) _reload();
    },
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.course.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${info.course.teacher} • ${info.total} Materi',
                style: const TextStyle(fontSize: 8.5),
              ),
              const SizedBox(height: 8),
              Text(
                '${info.pct}% Selesai',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Ui.blue,
                ),
              ),
              const SizedBox(height: 3),
              ProgressLine(value: info.pct / 100),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Ui.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
        ),
      ],
    ),
  );

  Widget _lockedCard(_CourseInfo info) => LockedCard(
    text: 'Selesaikan Course Sebelumnya',
    child: EduCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.course.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${info.course.teacher} • ${info.total} Materi',
                  style: const TextStyle(fontSize: 8.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _message(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Ui.muted),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _NotificationButton({
    required int count,
    required VoidCallback onTap,
  }) => IconButton(
    tooltip: 'Notifikasi',
    onPressed: onTap,
    icon: Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none_rounded, size: 27, color: Ui.navy),
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

  Widget _content(_DashData d) {
    final running = d.first(_St.running);
    final locked = d.first(_St.locked);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Student',
                    style: TextStyle(fontSize: 11),
                  ),
                  Text(
                    d.name,
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
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  RouteNames.studentNotifications,
                );
                if (mounted) _reload();
              },
            ),
            const SizedBox(width: 10),
            DarkAvatar(name: d.name, size: 34),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Ui.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress Belajar Kamu!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metric('${d.count(_St.done)}', 'Selesai'),
                  const SizedBox(width: 8),
                  _metric('${d.count(_St.running)}', 'Berjalan'),
                  const SizedBox(width: 8),
                  _metric('${d.count(_St.locked)}', 'Terkunci'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Lanjutkan Belajar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(
                context,
                RouteNames.studentCourses,
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Ui.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (d.courses.isEmpty)
          _message('Belum ada course.')
        else ...[
          if (running != null) _runningCard(running),
          if (running != null && locked != null) const SizedBox(height: 10),
          if (locked != null) _lockedCard(locked),
          if (running == null && locked == null)
            _message('Hebat! Semua course sudah selesai.'),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'student', current: 0),
    body: FutureBuilder<_DashData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Dashboard belum dapat dimuat.',
                style: TextStyle(fontSize: 11, color: Ui.muted),
              ),
              TextButton(onPressed: _reload, child: const Text('Coba lagi')),
            ],
          );
        }
        return _content(snapshot.data!);
      },
    ),
  );
}
