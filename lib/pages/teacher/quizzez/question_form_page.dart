import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class _Q {
  String? id;
  final question = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  final points = TextEditingController(text: '20');
  int correct = 0;

  _Q();

  _Q.fromRow(Map<String, dynamic> r) {
    id = r['id']?.toString();
    question.text = (r['question'] ?? '').toString();
    for (var i = 0; i < 4; i++) {
      options[i].text = (r['option_${String.fromCharCode(97 + i)}'] ?? '')
          .toString();
    }
    points.text = '${r['points'] ?? 20}';
    correct = (int.tryParse('${r['correct_option']}') ?? 0).clamp(0, 3);
  }

  bool get isBlank =>
      question.text.trim().isEmpty &&
      options.every((o) => o.text.trim().isEmpty);

  void dispose() {
    question.dispose();
    points.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

/// "Tambah Soal Quiz" - daftar soal + Draft / Tambah Soal / Publikasikan.
///
/// Argumen (dikirim TeacherQuizFormPage):
///   {'quiz_id': ..., 'quiz_title': ..., 'course_id': ...}
/// Draft: simpan soal lalu pop(true). Publikasikan: simpan soal, tandai quiz
/// 'published', lalu kembali ke detail course.
class TeacherQuestionFormPage extends StatefulWidget {
  const TeacherQuestionFormPage({super.key});
  @override
  State<TeacherQuestionFormPage> createState() =>
      _TeacherQuestionFormPageState();
}

class _TeacherQuestionFormPageState extends State<TeacherQuestionFormPage> {
  static const _questionTable = 'quiz_questions';
  static const _quizTable = 'quizzes';
  static const _quizKeys = ['id'];

  final _db = Supabase.instance.client;

  final List<_Q> questions = [];
  final List<String> _deletedIds = [];

  Object? _quizId;
  String _quizTitle = '';
  String _quizStatus = 'draft';

  bool _init = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  /// id quiz sebagai angka kalau memang angka (kolom bigint), kalau tidak apa adanya.
  Object? get _quizValue => _quizId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Map) {
      _quizId = arg['quiz_id']?.toString();
      _quizTitle = (arg['quiz_title'] ?? '').toString();
      _quizStatus = (arg['status'] ?? 'draft').toString();
    }
    _load();
  }

  @override
  void dispose() {
    for (final q in questions) {
      q.dispose();
    }
    super.dispose();
  }

  // ───────────────────────── DATA ─────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (_quizId == null) {
        throw 'Quiz tidak ditemukan. Kembali dan isi informasi quiz terlebih dahulu.';
      }

      final rows = List<Map<String, dynamic>>.from(
        await _db
            .from(_questionTable)
            .select()
            .eq('quiz_id', _quizValue!)
            .order('id'),
      );
      final quiz = await _db
          .from(_quizTable)
          .select('status')
          .eq('id', _quizValue!)
          .single();
      _quizStatus = (quiz['status'] ?? _quizStatus).toString();
      debugPrint(
        '[TeacherQuestionForm] ${rows.length} soal dimuat'
        '${rows.isNotEmpty ? ', kolom: ${rows.first.keys.toList()}' : ''}',
      );

      for (final q in questions) {
        q.dispose();
      }
      questions
        ..clear()
        ..addAll(rows.map(_Q.fromRow));
      if (questions.isEmpty) questions.add(_Q());
      _deletedIds.clear();
    } catch (e) {
      debugPrint('[TeacherQuestionForm] Gagal memuat data: $e');
      _loadError = '$e'.startsWith('Quiz tidak')
          ? '$e'
          : 'Gagal memuat data: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Kembalikan pesan error kalau ada soal yang belum benar, null kalau aman.
  String? _validate({required bool publish}) {
    var filled = 0;
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final no = i + 1;
      if (q.isBlank) {
        if (publish && questions.length > 1) {
          return 'Soal nomor $no masih kosong. Isi atau hapus soal tersebut.';
        }
        continue;
      }
      filled++;
      if (q.question.text.trim().isEmpty) {
        return 'Pertanyaan soal nomor $no belum ditulis.';
      }
      if (publish && q.options.any((o) => o.text.trim().isEmpty)) {
        return 'Semua pilihan jawaban soal nomor $no wajib diisi.';
      }
      final pts = int.tryParse(q.points.text.trim());
      if (pts == null || pts <= 0) {
        return 'Poin soal nomor $no harus angka lebih dari 0.';
      }
    }
    if (publish && filled == 0) return 'Tambahkan minimal 1 soal.';
    return null;
  }

  Map<String, dynamic> _toRow(_Q q) => {
    'quiz_id': _quizValue,
    'question': q.question.text.trim(),
    'option_a': q.options[0].text.trim(),
    'option_b': q.options[1].text.trim(),
    'option_c': q.options[2].text.trim(),
    'option_d': q.options[3].text.trim(),
    'correct_option': q.correct,
    'points': int.tryParse(q.points.text.trim()) ?? 0,
  };

  Future<bool> _saveQuestions() async {
    try {
      for (final id in _deletedIds) {
        await _db.from(_questionTable).delete().eq('id', id);
      }
      _deletedIds.clear();

      for (final q in questions) {
        if (q.isBlank) {
          // Soal tersimpan yang dikosongkan = dihapus
          if (q.id != null) {
            await _db.from(_questionTable).delete().eq('id', q.id!);
            q.id = null;
          }
          continue;
        }
        if (q.id != null) {
          await _db.from(_questionTable).update(_toRow(q)).eq('id', q.id!);
        } else {
          final created = await _db
              .from(_questionTable)
              .insert(_toRow(q))
              .select('id')
              .single();
          q.id = created['id']?.toString();
        }
      }
      await _db
          .from(_quizTable)
          .update({
            'question_count': questions
                .where((question) => !question.isBlank)
                .length,
          })
          .eq('id', _quizValue!);
      return true;
    } catch (e) {
      debugPrint('[TeacherQuestionForm] Gagal menyimpan soal: $e');
      _snack('Gagal menyimpan soal: $e');
      return false;
    }
  }

  /// Ubah status quiz ('draft' / 'published'). false = kolom status belum ada.
  Future<bool> _setStatus(String status) async {
    for (final k in _quizKeys) {
      try {
        await _db
            .from(_quizTable)
            .update({'status': status})
            .eq(k, _quizValue!);
        return true;
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('status')) {
          debugPrint(
            '[TeacherQuestionForm] Kolom status belum ada: ${e.message}',
          );
          return false;
        }
        if (e.code == '42703') continue; // kolom kunci salah, coba nama lain
        rethrow;
      }
    }
    return false;
  }

  Future<void> _draft() async {
    if (_saving) return;
    final err = _validate(publish: false);
    if (err != null) return _snack(err);

    setState(() => _saving = true);
    final ok = await _saveQuestions();
    if (ok) {
      try {
        await _setStatus(_quizStatus == 'published' ? 'published' : 'draft');
      } catch (e) {
        debugPrint('[TeacherQuestionForm] Gagal set status draft: $e');
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _publish() async {
    if (_saving) return;
    final err = _validate(publish: true);
    if (err != null) return _snack(err);

    final ok = await showConfirmWarning(
      context,
      title: 'Publikasi Quiz?',
      message: 'Anda yakin ingin mempublish quiz ini ?',
      primary: 'Ya, Yakin',
    );
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    var done = false;
    if (await _saveQuestions()) {
      try {
        done = await _setStatus('published');
        if (!done) {
          _snack(
            "Soal tersimpan, tapi kolom 'status' belum ada di tabel quiz.",
          );
        }
      } catch (e) {
        debugPrint('[TeacherQuestionForm] Gagal mempublikasi: $e');
        _snack('Gagal mempublikasi quiz: $e');
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (!done) return;

    await showSuccessDialog(context, 'Quiz Berhasil Dipublikasikan!');
    if (!mounted) return;
    Navigator.popUntil(
      context,
      (r) => r.settings.name == RouteNames.teacherCourseDetail || r.isFirst,
    );
  }

  void _removeQuestion(int index) {
    final q = questions[index];
    if (q.id != null) _deletedIds.add(q.id!);
    setState(() {
      questions.removeAt(index);
    });
    q.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ───────────────────────── UI ─────────────────────────

  Widget _questionBlock(int index, _Q q) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EduCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _chip('${index + 1}', true),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: q.question,
                maxLines: null,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Tulis pertanyaan disini',
                  hintStyle: TextStyle(fontSize: 10, color: Color(0xFFB6BFCC)),
                ),
              ),
            ),
            if (questions.length > 1)
              InkWell(
                onTap: _saving ? null : () => _removeQuestion(index),
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.close, size: 14, color: Ui.muted),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => q.correct = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: q.correct == i ? Ui.blueTint : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: q.correct == i ? Ui.blue : Ui.line),
                boxShadow: Ui.shadow,
              ),
              child: Row(
                children: [
                  _chip(String.fromCharCode(65 + i), q.correct == i),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: q.options[i],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Pilihan jawaban',
                        hintStyle: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB6BFCC),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.only(top: 4, bottom: 4),
        child: Text('Nilai', style: TextStyle(fontSize: 10)),
      ),
      Row(
        children: [
          SizedBox(
            width: 110,
            child: EduField(
              hint: '20',
              controller: q.points,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Poin',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );

  Widget _chip(String t, bool active) => Container(
    width: 20,
    height: 20,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: active ? Ui.blue : Ui.blueTint,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: active ? Colors.white : Ui.blue,
      ),
    ),
  );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              if (_quizId != null)
                TextButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      children: [
        for (var i = 0; i < questions.length; i++)
          _questionBlock(i, questions[i]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_loading && _loadError == null && !_saving;
    return Scaffold(
      backgroundColor: Ui.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                boxShadow: Ui.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackLink(),
                  const Text(
                    'Tambah Soal Quiz',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  if (_quizTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _quizTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Ui.muted),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _body()),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                10 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: Ui.shadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SolidBtn(
                      label: 'Draft',
                      bg: const Color(0xFFD1D5DB),
                      fg: Ui.text,
                      height: 34,
                      onTap: ready ? _draft : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SolidBtn(
                      label: 'Tambah Soal',
                      bg: Ui.blue,
                      height: 34,
                      onTap: ready
                          ? () => setState(() => questions.add(_Q()))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SolidBtn(
                      label: 'Publikasikan',
                      bg: Ui.green,
                      height: 34,
                      onTap: ready ? _publish : null,
                    ),
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
