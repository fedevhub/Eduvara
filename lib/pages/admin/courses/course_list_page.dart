import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

/// Nama tabel Supabase (ubah di sini kalau berbeda)
const _tCourse = 'course';
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
    final raw = _pick(c, ['percent', 'progress', 'completion_rate']);
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
      final courseData = await _db.from(_tCourse).select('*');
      final courses = List<Map<String, dynamic>>.from(courseData as List);

      // Nama guru (opsional, hanya kalau tabel profiles bisa dibaca)
      final names = <String, String>{};
      try {
        final pd = await _db.from(_tProfiles).select('*');
        for (final p in List<Map<String, dynamic>>.from(pd as List)) {
          final id = p['id'];
          if (id == null) continue;
          names['$id'] =
              (_pick(p, ['full_name', 'name', 'nama']) ?? '-').toString();
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
      await _db.from(_tCourse).delete().eq(key, c[key]);
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

  /// Buka page lain, lalu muat ulang data saat kembali.
  Future<void> _go(String route, {Object? arguments}) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    if (mounted) _load();
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
          PageTitle(
            'Manajemen Course',
            onAdd: () => _go(RouteNames.adminCourseForm),
          ),
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
                  onTap: () => _go(RouteNames.adminCourseDetail, arguments: c),
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
                              onTap: () => _go(
                                RouteNames.adminCourseForm,
                                arguments: c,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SoftBtn.delete(onTap: () => _delete(c)),
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