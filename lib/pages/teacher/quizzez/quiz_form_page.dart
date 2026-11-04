import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

/// "Tambah Informasi Quiz" - langkah 1 sebelum menambah soal.
///
/// Argumen yang dikenali:
///   - null                      → quiz baru
///   - int / String angka        → id quiz (mode edit)
///   - String UUID               → id course (tambah quiz untuk course tersebut)
///   - Map {'id'/'quiz_id', 'course_id'} → edit quiz / course untuk quiz baru
/// Course tidak dipilih di form ini, tapi dibawa dari halaman sebelumnya.
/// Setelah disimpan, halaman soal dibuka dengan argumen:
///   {'quiz_id': ..., 'quiz_title': ..., 'course_id': ...}
/// Kalau halaman soal selesai dan pop(true), halaman ini ikut pop(true)
/// supaya halaman daftar quiz bisa refresh.
class TeacherQuizFormPage extends StatefulWidget {
  const TeacherQuizFormPage({super.key});
  @override
  State<TeacherQuizFormPage> createState() => _TeacherQuizFormPageState();
}

class _TeacherQuizFormPageState extends State<TeacherQuizFormPage> {
  static const _table = 'quizzes';
  static const _idKeys = ['id'];

  /// Kemungkinan nama kolom di tabel quiz untuk tiap isian form.
  /// Kode mencoba berurutan sampai ketemu yang benar-benar ada.
  static const _candidates = <String, List<String>>{
    'course': ['course_id'],
    'title': ['title'],
    'duration': ['duration_minutes'],
    'min': ['passing_score'],
    'owner': [],
  };
  static const _labels = {
    'course': 'course',
    'title': 'judul quiz',
    'duration': 'durasi',
    'min': 'nilai minimal',
    'owner': 'pembuat quiz',
  };

  static final _numeric = RegExp(r'^\d+$');
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final title = TextEditingController();
  final duration = TextEditingController();
  final minScore = TextEditingController();

  final _db = Supabase.instance.client;

  String? _courseId;
  String? _quizId; // terisi saat edit, atau setelah quiz pertama kali disimpan
  String _idKey = 'id'; // nama kolom kunci tabel quiz (terdeteksi otomatis)

  /// Indeks kandidat yang sedang dipakai untuk tiap isian.
  final Map<String, int> _pick = {};

  bool _init = false;
  bool _loading = true;
  bool _saving = false;
  String _quizStatus = 'draft';
  String? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    debugPrint('[TeacherQuizForm] argumen diterima: $arg (${arg.runtimeType})');

    if (arg is int) {
      _quizId = arg.toString();
    } else if (arg is String) {
      final a = arg.trim();
      if (_numeric.hasMatch(a)) {
        _quizId = a; // id quiz bertipe angka (bigint)
      } else if (_uuid.hasMatch(a)) {
        _courseId = a; // UUID bukan id quiz → kemungkinan id course
      }
    } else if (arg is Map) {
      final id = (arg['id'] ?? arg['quiz_id'])?.toString();
      if (id != null && id.isNotEmpty) _quizId = id;
      _courseId = arg['course_id']?.toString();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in [title, duration, minScore]) {
      c.dispose();
    }
    super.dispose();
  }

  // ───────────────────────── DATA ─────────────────────────

  // ── pencocokan kolom ──

  /// Nama kolom yang sedang dipakai untuk [field], null kalau kandidat habis.
  String? _col(String field) {
    final i = _pick[field] ?? 0;
    final list = _candidates[field]!;
    return i < list.length ? list[i] : null;
  }

  /// Ambil nilai [field] dari baris quiz, sekaligus mengunci nama kolomnya.
  dynamic _readField(Map<String, dynamic> row, String field) {
    final list = _candidates[field]!;
    for (var i = 0; i < list.length; i++) {
      if (row.containsKey(list[i])) {
        _pick[field] = i;
        return row[list[i]];
      }
    }
    return null;
  }

  /// Ambil nama kolom yang ditolak dari pesan error Postgrest.
  String? _missingColumn(PostgrestException e) {
    final m =
        RegExp(r"Could not find the '([^']+)' column").firstMatch(e.message) ??
        RegExp(
          r'column (?:\w+\.)?"?(\w+)"? does not exist',
        ).firstMatch(e.message);
    return m?.group(1);
  }

  /// Simpan quiz; kalau ada nama kolom yang tidak cocok, geser ke kandidat berikutnya.
  Future<Map<String, dynamic>?> _writeQuiz({
    required bool insert,
    required String quizTitle,
    required int dur,
    required int min,
    required String uid,
  }) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      // Isian wajib yang kandidatnya sudah habis → hentikan dengan pesan jelas
      for (final f in ['course', 'title', 'duration', 'min']) {
        if (_col(f) == null) {
          throw 'Tabel $_table tidak punya kolom untuk ${_labels[f]}. '
              'Nama yang dicoba: ${_candidates[f]!.join(', ')}. '
              'Cek nama kolom aslinya di Supabase.';
        }
      }

      final data = <String, dynamic>{
        _col('course')!: _courseId,
        _col('title')!: quizTitle,
        _col('duration')!: dur,
        _col('min')!: min,
        if (insert) 'status': 'draft',
        if (insert && _col('owner') != null) _col('owner')!: uid,
      };

      try {
        if (insert) {
          return await _db.from(_table).insert(data).select().single();
        }
        await _db.from(_table).update(data).eq(_idKey, _quizId!);
        return null;
      } on PostgrestException catch (e) {
        final missing = (e.code == 'PGRST204' || e.code == '42703')
            ? _missingColumn(e)
            : null;
        if (missing == null) rethrow;

        final field = _candidates.keys.firstWhere(
          (f) => _col(f) == missing,
          orElse: () => '',
        );
        if (field.isEmpty) rethrow;
        debugPrint(
          '[TeacherQuizForm] kolom "$missing" tidak ada, coba nama lain',
        );
        _pick[field] = (_pick[field] ?? 0) + 1;
      }
    }
    throw 'Gagal mencocokkan nama kolom tabel $_table.';
  }

  /// Ambil satu quiz; coba beberapa kemungkinan nama kolom kunci.
  Future<Map<String, dynamic>> _fetchQuiz(String id) async {
    Object? lastError;
    for (final k in _idKeys) {
      try {
        final q = await _db.from(_table).select().eq(k, id).single();
        _idKey = k;
        return q;
      } on PostgrestException catch (e) {
        if (e.code == '42703') {
          lastError = e; // kolom tidak ada, coba nama berikutnya
          continue;
        }
        rethrow;
      }
    }
    throw lastError ?? 'Quiz tidak ditemukan.';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) throw 'Sesi login tidak ditemukan.';

      // Mode edit: isi form dari data quiz
      if (_quizId != null) {
        final q = await _fetchQuiz(_quizId!);
        debugPrint('[TeacherQuizForm] kolom $_table: ${q.keys.toList()}');
        title.text = (_readField(q, 'title') ?? '').toString();
        duration.text = (_readField(q, 'duration') ?? '').toString();
        minScore.text = (_readField(q, 'min') ?? '').toString();
        _courseId = _readField(q, 'course')?.toString();
        _readField(q, 'owner');
        _quizStatus = (q['status'] ?? 'draft').toString();
      }
    } catch (e) {
      debugPrint('[TeacherQuizForm] Gagal memuat data: $e');
      _loadError = 'Gagal memuat data: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _next() async {
    if (_saving) return;

    final quizTitle = title.text.trim();
    final dur = int.tryParse(duration.text.trim());
    final min = int.tryParse(minScore.text.trim());

    if (_courseId == null) {
      return _snack(
        'Course tidak diketahui. Buka halaman ini dari detail course.',
      );
    }
    if (quizTitle.isEmpty) return _snack('Judul quiz wajib diisi.');
    if (dur == null || dur <= 0) {
      return _snack('Durasi wajib diisi dengan angka lebih dari 0 (menit).');
    }
    if (min == null || min < 0 || min > 100) {
      return _snack('Nilai minimal wajib diisi dengan angka 0 - 100.');
    }

    final uid = _db.auth.currentUser?.id;
    if (uid == null) return _snack('Sesi login tidak ditemukan.');

    setState(() => _saving = true);
    try {
      final created = await _writeQuiz(
        insert: _quizId == null,
        quizTitle: quizTitle,
        dur: dur,
        min: min,
        uid: uid,
      );
      debugPrint(
        '[TeacherQuizForm] kolom dipakai: '
        '${_candidates.keys.map((f) => '$f=${_col(f)}').join(', ')}',
      );

      if (created != null) {
        debugPrint('[TeacherQuizForm] kolom $_table: ${created.keys.toList()}');
        // Simpan id supaya kalau kembali dari halaman soal lalu menekan
        // "Selanjutnya" lagi, quiz yang sama diperbarui, bukan dibuat ganda.
        _idKey = _idKeys.firstWhere(created.containsKey, orElse: () => 'id');
        _quizId = created[_idKey].toString();
      }
    } catch (e) {
      debugPrint('[TeacherQuizForm] Gagal menyimpan quiz: $e');
      if (mounted) {
        _snack('Gagal menyimpan quiz: $e');
        setState(() => _saving = false);
      }
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final result = await Navigator.pushNamed(
      context,
      RouteNames.teacherQuestionForm,
      arguments: {
        'quiz_id': _quizId,
        'quiz_title': quizTitle,
        'course_id': _courseId,
        'status': _quizStatus,
      },
    );
    if (!mounted) return;
    if (result == true) Navigator.pop(context, true);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        const SizedBox(height: 4),
        Text(
          _quizId == null ? 'Tambah Informasi Quiz' : 'Edit Informasi Quiz',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_loadError != null)
          Center(
            child: Column(
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextButton(onPressed: _load, child: const Text('Coba lagi')),
              ],
            ),
          )
        else
          _form(),
      ],
    ),
  );

  Widget _form() => FormCard(
    children: [
      const FieldLabel('Judul Quiz', required: true),
      EduField(controller: title),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('Durasi (menit)', required: true),
                EduField(
                  controller: duration,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('Nilai Minimal', required: true),
                EduField(
                  controller: minScore,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SolidBtn(label: 'Selanjutnya', onTap: _saving ? null : _next),
    ],
  );
}
