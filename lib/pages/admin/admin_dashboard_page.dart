import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';

class _T {
  static const profiles = 'profiles';
  static const courses = 'course';
  static const quizzes = 'quiz';
  static const notifications = 'notifications';
}

class _CourseRate {
  final String title;
  final int percent;
  const _CourseRate(this.title, this.percent);
}

class _ActivityItem {
  final String title;
  final DateTime? createdAt;
  const _ActivityItem(this.title, this.createdAt);
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
  }) async {
    try {
      final base = _db.from(table).select(columns);
      final data = orderBy == null
          ? await base
          : await base.order(orderBy, ascending: false);
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

    // select('*') supaya tidak error karena nama kolom beda.
    final results = await Future.wait([
      _fetch(_T.profiles, '*'),
      _fetch(_T.courses, '*'),
      _fetch(_T.quizzes, '*'),
      _fetch(_T.notifications, '*'),
    ]);

    if (!mounted) return;

    final profiles = results[0];
    final courses = results[1];
    final quizzes = results[2];
    final notifs = results[3];

    // Debug: lihat kolom asli tiap tabel di console
    for (final entry in {
      'profiles': profiles,
      'course': courses,
      'quiz': quizzes,
      'notifications': notifs,
    }.entries) {
      if (entry.value.isNotEmpty) {
        debugPrint('[AdminDashboard] kolom ${entry.key}: '
            '${entry.value.first.keys.toList()}');
      }
    }

    // Nama admin yang sedang login
    final uid = _db.auth.currentUser?.id;
    final me = profiles.where((p) => p['id'] == uid).toList();
    final name = me.isNotEmpty
        ? _pick(me.first, ['full_name', 'name', 'nama'])?.toString()
        : null;

    // Completion rate: pakai kolom persentase/progress di tabel course
    final rates = courses.map((course) {
      final raw = _pick(course, [
        'percent',
        'progress',
        'completion_rate',
        'completion',
        'completed_percent',
      ]);
      final value = raw is num ? raw.round() : int.tryParse('$raw') ?? 0;
      return _CourseRate(
        (_pick(course, ['title', 'name', 'nama', 'judul']) ?? '-').toString(),
        value.clamp(0, 100).toInt(),
      );
    }).toList();

    // Notifikasi: urutkan terbaru di atas (kalau ada kolom tanggal)
    DateTime? dateOf(Map<String, dynamic> n) => DateTime.tryParse(
          '${_pick(n, ['created_at', 'date', 'time', 'timestamp'])}',
        )?.toLocal();
    notifs.sort((x, y) {
      final dx = dateOf(x), dy = dateOf(y);
      if (dx == null || dy == null) return 0;
      return dy.compareTo(dx);
    });

    bool isRead(Map<String, dynamic> n) =>
        _pick(n, ['read', 'is_read', 'isRead', 'dibaca']) == true;

    setState(() {
      _adminName = (name == null || name.isEmpty) ? 'Admin' : name;
      _totalSiswa =
          profiles.where((p) => _isRole(p, ['student', 'siswa'])).length;
      _totalGuru =
          profiles.where((p) => _isRole(p, ['teacher', 'guru'])).length;
      _totalKursus = courses.length;
      _totalQuiz = quizzes.length;
      _unreadNotifications = notifs.where((n) => !isRead(n)).length;
      _rates = rates;
      _activities = notifs.take(3).map((n) {
        return _ActivityItem(
          (_pick(n, ['title', 'judul', 'message', 'body']) ?? '-').toString(),
          dateOf(n),
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
              const DarkAvatar(size: 34),
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
                  onTap: _openNotifications,
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