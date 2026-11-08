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

  final _db = Supabase.instance.client;

  int tab = 0;
  bool _loading = true;
  String? _error;
  bool _argsRead = false;
  String? _courseId;

  String _title = '';
  String _teacherName = '-';
  String _description = '';
  String _subject = '-';
  String _gradeLevel = '-';
  String _status = 'active';
  int _percent = 0;

  List<Map<String, String>> _students = [];
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
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return def;
  }

  String _safeTitle(
    Map<String, dynamic> row,
    List<String> keys,
    String fallbackPrefix, [
    int index = 0,
  ]) {
    final raw = _pick(row, keys, '');
    final text = raw.trim();
    if (text.isNotEmpty && text != 'null' && !RegExp(r'^\d+$').hasMatch(text)) {
      return text;
    }
    return '$fallbackPrefix ${index + 1}';
  }

  String _subtitleForMaterial(Map<String, dynamic> row, [int index = 0]) {
    final created = _formatDate(row['created_at']);
    if (created.isNotEmpty) return created;
    final desc = _pick(row, ['description', 'deskripsi', 'summary'], '');
    if (desc.isNotEmpty && desc != 'null') return desc;
    return 'Materi ${index + 1}';
  }

  String _subtitleForQuiz(Map<String, dynamic> row, [int index = 0]) {
    final desc = _pick(row, ['description', 'deskripsi', 'summary'], '');
    if (desc.isNotEmpty && desc != 'null') return desc;
    final created = _formatDate(row['created_at']);
    if (created.isNotEmpty) return created;
    return 'Quiz ${index + 1}';
  }

  String _formatDate(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${days[d.weekday - 1]}, ${two(d.day)}-${two(d.month)}-${d.year}';
  }

  // ---------- load ----------
  Future<void> _load() async {
    if (_courseId == null) {
      setState(() {
        _loading = false;
        _error =
            'Course tidak ditemukan (id kosong).\n'
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
          .select(
            'id, title, description, teacher_id, subject, grade_level, status',
          )
          .eq('id', _courseId!)
          .single();

      var teacher = '-';
      final tid = course['teacher_id'];
      if (tid != null) {
        final p = await _db
            .from('profiles')
            .select('full_name')
            .eq('id', tid)
            .maybeSingle();
        teacher = (p?['full_name'] ?? '-').toString();
      }

      var percent = 0;
      final enrollments = await _db
          .from(_tEnrollments)
          .select('student_id')
          .eq('course_id', _courseId!);
      final materialIds = await _db
          .from('materials')
          .select('id')
          .eq('course_id', _courseId!);
      if (enrollments.isNotEmpty && materialIds.isNotEmpty) {
        final progress = await _db
            .from('material_progress')
            .select('material_id')
            .eq('completed', true)
            .inFilter(
              'user_id',
              enrollments.map((row) => row['student_id']).toList(),
            )
            .inFilter(
              'material_id',
              materialIds.map((row) => row['id']).toList(),
            );
        percent =
            (progress.length / (enrollments.length * materialIds.length) * 100)
                .round();
      }

      final studentIds = enrollments
          .map((row) => row['student_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final students = <Map<String, String>>[];
      if (studentIds.isNotEmpty) {
        final profiles = await _db
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', studentIds);
        final accounts = await _db
            .from('user')
            .select('id_user, kelas')
            .inFilter('id_user', studentIds);
        final classes = {
          for (final account in accounts)
            account['id_user'].toString(): (account['kelas'] ?? '-').toString(),
        };
        students.addAll(
          List<Map<String, dynamic>>.from(profiles).map(
            (profile) => {
              'name': (profile['full_name'] ?? 'Tanpa nama').toString(),
              'class_name': classes[profile['id'].toString()] ?? '-',
            },
          ),
        );
        students.sort(
          (a, b) =>
              a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
        );
      }

      final materialRows = List<Map<String, dynamic>>.from(
        await _db
            .from('materials')
            .select()
            .eq('course_id', _courseId!)
            .order('order_no'),
      );
      final quizRows = List<Map<String, dynamic>>.from(
        await _db
            .from('quizzes')
            .select()
            .eq('course_id', _courseId!)
            .order('order_no'),
      );

      if (!mounted) return;
      setState(() {
        _title = (course['title'] ?? '-').toString();
        _description = (course['description'] ?? '').toString();
        _teacherName = teacher;
        _subject = (course['subject'] ?? course['mapel'] ?? '-').toString();
        _gradeLevel = (course['grade_level'] ?? course['level'] ?? '-')
            .toString();
        _status = (course['status'] ?? 'active').toString();
        _percent = percent.clamp(0, 100);
        _students = students;
        _materials = materialRows;
        _quizzes = quizRows;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus $what: $e')));
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
      await Navigator.pushNamed(
        context,
        RouteNames.teacherMaterialForm,
        arguments: {'course_id': _courseId},
      );
    } else {
      await Navigator.pushNamed(
        context,
        RouteNames.teacherMaterialForm,
        arguments: {'id': m['id'], 'course_id': _courseId},
      );
    }
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
                  TextButton(onPressed: _load, child: const Text('Coba lagi')),
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
    EduCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Ui.blueTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Ui.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _description,
                    style: const TextStyle(fontSize: 10, color: Ui.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    EduCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _courseFact(
                  Icons.person_outline,
                  'Pengajar',
                  _teacherName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _courseFact(
                  Icons.check_circle_outline,
                  'Status',
                  _status,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: _courseFact(
                  Icons.menu_book_outlined,
                  'Mata Pelajaran',
                  _subject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _courseFact(
                  Icons.groups_outlined,
                  'Jumlah Siswa',
                  '${_students.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _courseFact(Icons.school_outlined, 'Kelas', _gradeLevel),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: StatBox(value: '${_materials.length}', label: 'Materi'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBox(value: '${_quizzes.length}', label: 'Quiz'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBox(value: '$_percent%', label: 'Selesai'),
        ),
      ],
    ),
    const SizedBox(height: 16),
    SegTabs(
      labels: const ['Daftar Siswa', 'Materi', 'Quiz'],
      index: tab,
      onChanged: (i) => setState(() => tab = i),
    ),
    const SizedBox(height: 12),
    if (tab == 0) ..._studentTab(),
    if (tab == 1) ..._materialTab(),
    if (tab == 2) ..._quizTab(),
  ];

  Widget _courseFact(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 19, color: Ui.navy),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Ui.muted)),
            Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );

  List<Widget> _studentTab() => [
    if (_students.isEmpty) _empty('Belum ada siswa pada course ini.'),
    if (_students.isNotEmpty)
      EduCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            for (var index = 0; index < _students.length; index++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: index == _students.length - 1
                      ? null
                      : const Border(bottom: BorderSide(color: Ui.line)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Ui.blueTint,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Ui.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _students[index]['name']!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _students[index]['class_name'] == '-'
                                ? 'Kelas -'
                                : _students[index]['class_name']!,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Ui.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
  ];

  List<Widget> _materialTab() => [
    _manageButton('Tambah / Kelola Materi', () => _goMaterialForm()),
    const SizedBox(height: 12),
    if (_materials.isEmpty) _empty('Belum ada materi'),
    for (var i = 0; i < _materials.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EduCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Ui.blueTint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Ui.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeTitle(
                        _materials[i],
                        ['title', 'judul', 'name', 'materi_title'],
                        'Materi',
                        i,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _subtitleForMaterial(_materials[i], i),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 8.5, color: Ui.muted),
                    ),
                  ],
                ),
              ),
              _iconBtn(
                Icons.visibility_outlined,
                Ui.greenSoft,
                Ui.greenDark,
                () => Navigator.pushNamed(
                  context,
                  RouteNames.teacherMaterialDetail,
                  arguments: {'id': _materials[i]['id']},
                ),
              ),
              _iconBtn(
                Icons.edit_outlined,
                Ui.blueSoft,
                Ui.blue,
                () => _goMaterialForm(_materials[i]),
              ),
              _iconBtn(
                Icons.delete_outline,
                Ui.redSoft,
                Ui.red,
                () => _delete(
                  what: 'Materi',
                  table: 'materials',
                  id: _materials[i]['id'],
                ),
              ),
            ],
          ),
        ),
      ),
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
      child: Text(text, style: const TextStyle(fontSize: 10, color: Ui.muted)),
    ),
  );

  List<Widget> _quizTab() => [
    _manageButton('Tambah / Kelola Quiz', _addQuiz),
    const SizedBox(height: 12),
    const Text(
      'Daftar Quiz',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    if (_quizzes.isEmpty) _empty('Belum ada quiz'),
    for (var i = 0; i < _quizzes.length; i++)
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
                      _safeTitle(
                        _quizzes[i],
                        ['title', 'judul', 'name', 'quiz_title'],
                        'Quiz',
                        i,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _subtitleForQuiz(_quizzes[i], i),
                      style: const TextStyle(fontSize: 8.5),
                    ),
                  ],
                ),
              ),
              _iconBtn(
                Icons.visibility_outlined,
                Ui.greenSoft,
                Ui.greenDark,
                () => Navigator.pushNamed(
                  context,
                  RouteNames.teacherQuizDetail,
                  arguments: {'id': _quizzes[i]['id']},
                ),
              ),
              _iconBtn(
                Icons.edit_outlined,
                Ui.blueSoft,
                Ui.blue,
                () =>
                    Navigator.pushNamed(
                      context,
                      RouteNames.teacherQuizForm,
                      arguments: {
                        'quiz_id': _quizzes[i]['id'],
                        'course_id': _courseId,
                      },
                    ).then((_) {
                      if (mounted) _load();
                    }),
              ),
              _iconBtn(
                Icons.delete_outline,
                Ui.redSoft,
                Ui.red,
                () => _delete(
                  what: 'Quiz',
                  table: 'quizzes',
                  id: _quizzes[i]['id'],
                ),
              ),
            ],
          ),
        ),
      ),
  ];
}
