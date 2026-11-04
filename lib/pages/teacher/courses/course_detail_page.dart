import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class TeacherCourseDetailPage extends StatefulWidget {
  const TeacherCourseDetailPage({super.key});
  @override
  State<TeacherCourseDetailPage> createState() =>
      _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  // Kandidat nama tabel/kolom. Setelah tahu yang benar dari log, sisakan satu.
  static const _tCourses = 'courses';
  static const _tEnrollments = 'enrollments';
  static const _materialTables = ['material', 'materials', 'materi', 'modules'];
  static const _quizTables = ['quiz', 'quizzes'];
  static const _courseCols = [
    'course_id',
    'courses_id',
    'id_course',
    'id_courses',
    'course',
  ];

  final _db = Supabase.instance.client;

  int tab = 0;
  bool _loading = true;
  String? _error;
  bool _argsRead = false;
  String? _courseId;

  String _title = '';
  String _teacherName = '-';
  String _description = '';
  int _percent = 0;

  String? _matTable, _matCol, _quizTable, _quizCol;

  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _courseId = (args['id'] ?? args['course_id'])?.toString();
    } else if (args != null) {
      _courseId = args.toString();
    }
    _load();
  }

  // ---------- helpers ----------
  String _pick(Map<String, dynamic> r, List<String> keys, [String def = '']) {
    for (final k in keys) {
      final v = r[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return def;
  }

  String _formatDate(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${days[d.weekday - 1]}, ${two(d.day)}-${two(d.month)}-${d.year}';
  }

  Future<({String table, String col, List<Map<String, dynamic>> rows})?>
      _findRows(List<String> tables, String? knownT, String? knownC) async {
    final ts = knownT != null ? [knownT] : tables;
    final cs = knownC != null ? [knownC] : _courseCols;
    for (final t in ts) {
      for (final c in cs) {
        try {
          final rows = await _db.from(t).select().eq(c, _courseId!);
          debugPrint('Detail: pakai $t.$c');
          return (
            table: t,
            col: c,
            rows: List<Map<String, dynamic>>.from(rows),
          );
        } on PostgrestException catch (e) {
          if (e.code == 'PGRST205') break; // tabel tidak ada
        } catch (_) {}
      }
    }
    debugPrint('Detail: tabel/kolom tidak ketemu untuk $tables');
    return null;
  }

  void _sortNewest(List<Map<String, dynamic>> rows) {
    rows.sort((a, b) {
      final x = a['created_at']?.toString() ?? '';
      final y = b['created_at']?.toString() ?? '';
      return y.compareTo(x);
    });
  }

  // ---------- load ----------
  Future<void> _load() async {
    if (_courseId == null) {
      setState(() {
        _loading = false;
        _error = 'Course tidak ditemukan (id kosong).\n'
            'Buka halaman ini dari daftar course.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final course = await _db
          .from(_tCourses)
          .select('id, title, description, teacher_id')
          .eq('id', _courseId!)
          .single();

      var teacher = '-';
      final tid = course['teacher_id'];
      if (tid != null) {
        try {
          final p = await _db
              .from('profiles')
              .select('full_name')
              .eq('id', tid)
              .maybeSingle();
          teacher = (p?['full_name'] ?? '-').toString();
        } catch (e) {
          debugPrint('Gagal ambil nama guru: $e');
        }
      }

      var percent = 0;
      try {
        final en = await _db
            .from(_tEnrollments)
            .select()
            .eq('course_id', _courseId!);
        debugPrint(
          'Detail: kolom enrollments = '
          '${en.isNotEmpty ? en.first.keys.toList() : 'kosong'}',
        );

        if (en.isNotEmpty) {
          final withProgress = en.where((r) => r['progress'] is num).toList();
          if (withProgress.isNotEmpty) {
            final sum = withProgress.fold<num>(
              0,
              (a, r) => a + (r['progress'] as num),
            );
            percent = (sum / withProgress.length).round();
          } else if (en.any((r) => r.containsKey('status'))) {
            final done = en.where((r) => r['status'] == 'completed').length;
            percent = (done / en.length * 100).round();
          }
        }
      } catch (e) {
        debugPrint('Gagal hitung persentase: $e');
      }

      final mat = await _findRows(_materialTables, _matTable, _matCol);
      final quiz = await _findRows(_quizTables, _quizTable, _quizCol);
      if (mat != null) {
        _matTable = mat.table;
        _matCol = mat.col;
        _sortNewest(mat.rows);
      }
      if (quiz != null) {
        _quizTable = quiz.table;
        _quizCol = quiz.col;
        _sortNewest(quiz.rows);
      }

      if (!mounted) return;
      setState(() {
        _title = (course['title'] ?? '-').toString();
        _description = (course['description'] ?? '').toString();
        _teacherName = teacher;
        _percent = percent.clamp(0, 100);
        _materials = mat?.rows ?? [];
        _quizzes = quiz?.rows ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('[TeacherCourseDetail] error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---------- actions ----------
  Future<void> _delete({
    required String what,
    required String? table,
    required dynamic id,
  }) async {
    if (table == null || id == null) return;
    final ok = await showConfirmDanger(
      context,
      title: 'Hapus $what?',
      message: 'Data yang dihapus tidak dapat dikembalikan.',
    );
    if (!ok || !mounted) return;
    try {
      await _db.from(table).delete().eq('id', id);
      await _load();
      if (!mounted) return;
      await showSuccessDialog(context, '$what Berhasil di Hapus');
    } catch (e) {
      debugPrint('[TeacherCourseDetail] Gagal hapus $what: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus $what: $e')),
      );
    }
  }

  Future<void> _addQuiz() async {
    await Navigator.pushNamed(
      context,
      RouteNames.teacherQuizForm,
      arguments: _courseId,
    );
    if (mounted) _load();
  }

  // Navigasi ke halaman lain: bentuk arguments SAMA seperti file asli
  // supaya router tidak menolak.
  Future<void> _goMaterialForm([Map<String, dynamic>? m]) async {
    if (m == null) {
      await Navigator.pushNamed(context, RouteNames.teacherMaterialForm);
    } else {
      await Navigator.pushNamed(
        context,
        RouteNames.teacherMaterialForm,
        arguments: _pick(m, ['title', 'judul', 'name']),
      );
    }
    if (mounted) _load();
  }

  Future<void> _goQuestionForm() async {
    await Navigator.pushNamed(context, RouteNames.teacherQuestionForm);
    if (mounted) _load();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Gagal memuat course.\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Ui.muted),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          )
        else
          ..._content(),
      ],
    ),
  );

  List<Widget> _content() => [
    Text(
      _title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    ),
    Text(_teacherName, style: const TextStyle(fontSize: 9)),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: StatBox(value: '${_materials.length}', label: 'Materi'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatBox(value: '${_quizzes.length}', label: 'Quiz'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatBox(value: '$_percent%', label: 'Selesai'),
        ),
      ],
    ),
    if (_description.isNotEmpty) ...[
      const SizedBox(height: 10),
      Text(_description, style: const TextStyle(fontSize: 9)),
    ],
    const SizedBox(height: 10),
    SegTabs(
      labels: const ['Course', 'Quiz'],
      index: tab,
      onChanged: (i) => setState(() => tab = i),
    ),
    const SizedBox(height: 12),
    if (tab == 0) ..._courseTab() else ..._quizTab(),
  ];

  Widget _manageButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Ui.blueSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Ui.blue.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 15, color: Ui.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Ui.blue,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _iconBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: fg),
        ),
      );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Ui.muted),
      ),
    ),
  );

  List<Widget> _courseTab() => [
    _manageButton('Tambah / Kelola Materi', () => _goMaterialForm()),
    const SizedBox(height: 12),
    const Text(
      'Daftar Course',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    if (_materials.isEmpty) _empty('Belum ada materi'),
    for (final m in _materials)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EduCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pick(m, ['title', 'judul', 'name'], '-'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatDate(m['created_at']),
                      style: const TextStyle(fontSize: 8.5),
                    ),
                  ],
                ),
              ),
              _iconBtn(
                Icons.edit_outlined,
                Ui.blueSoft,
                Ui.blue,
                () => _goMaterialForm(m),
              ),
              _iconBtn(
                Icons.delete_outline,
                Ui.redSoft,
                Ui.red,
                () => _delete(what: 'Materi', table: _matTable, id: m['id']),
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _quizTab() => [
    _manageButton('Tambah / Kelola Quiz', _addQuiz),
    const SizedBox(height: 12),
    const Text(
      'Daftar Quiz',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    if (_quizzes.isEmpty) _empty('Belum ada quiz'),
    for (final q in _quizzes)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EduCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pick(q, ['title', 'judul', 'name'], '-'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _pick(q, ['description', 'deskripsi']),
                      style: const TextStyle(fontSize: 8.5),
                    ),
                  ],
                ),
              ),
              _iconBtn(
                Icons.edit_outlined,
                Ui.blueSoft,
                Ui.blue,
                _goQuestionForm,
              ),
              _iconBtn(
                Icons.delete_outline,
                Ui.redSoft,
                Ui.red,
                () => _delete(what: 'Quiz', table: _quizTable, id: q['id']),
              ),
            ],
          ),
        ),
      ),
  ];
}