import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class StudentCourseDetailPage extends StatefulWidget {
  const StudentCourseDetailPage({super.key});
  @override
  State<StudentCourseDetailPage> createState() =>
      _StudentCourseDetailPageState();
}

class _StudentCourseDetailPageState extends State<StudentCourseDetailPage> {
  final _db = Supabase.instance.client;

  int tab = 0;
  bool _loading = true;
  String? _error;
  String? _courseId;

  Map<String, dynamic>? _course;
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _quizzes = [];
  Set<String> _doneMaterials = {};
  Set<String> _doneQuizzes = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final nextCourseId = args is Map && args['course_id'] != null
        ? args['course_id'].toString()
        : null;

    if (nextCourseId == null) {
      if (_courseId != null) _courseId = null;
      _loading = false;
      _error = 'Course tidak ditemukan';
      return;
    }

    if (_courseId != nextCourseId || _course == null) {
      _courseId = nextCourseId;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) throw 'Sesi login berakhir, silakan login ulang';

      final results = await Future.wait(<Future<dynamic>>[
        _db.from('courses').select().eq('id', _courseId!).single(),
        () async {
          try {
            final rows = await _db
                .from('materials')
                .select()
                .eq('course_id', _courseId!)
                .order('order_no');
            return List<Map<String, dynamic>>.from(rows as List);
          } on PostgrestException catch (e) {
            if (e.code != 'PGRST205') rethrow;
            return <Map<String, dynamic>>[];
          }
        }(),
        () async {
          try {
            final rows = await _db
                .from('quizzes')
                .select()
                .eq('course_id', _courseId!)
                .order('order_no');
            return List<Map<String, dynamic>>.from(rows as List);
          } on PostgrestException catch (e) {
            if (e.code != 'PGRST205') rethrow;
            return <Map<String, dynamic>>[];
          }
        }(),
      ]);

      final materials = List<Map<String, dynamic>>.from(results[1] as List);
      final quizzes = List<Map<String, dynamic>>.from(results[2] as List);

      final matIds = materials.map((e) => e['id']).toList();
      final quizIds = quizzes.map((e) => e['id']).toList();

      List<dynamic> doneMat = const [];
      List<dynamic> doneQuiz = const [];

      if (matIds.isNotEmpty) {
        try {
          doneMat = await _db
              .from('material_progress')
              .select('material_id')
              .eq('user_id', uid)
              .eq('completed', true)
              .inFilter('material_id', matIds);
        } on PostgrestException catch (e) {
          if (e.code != 'PGRST205') rethrow;
        }
      }

      if (quizIds.isNotEmpty) {
        try {
          doneQuiz = await _db
              .from('quiz_attempts')
              .select('quiz_id')
              .eq('user_id', uid)
              .eq('completed', true)
              .inFilter('quiz_id', quizIds);
        } on PostgrestException catch (e) {
          if (e.code != 'PGRST205') rethrow;
        }
      }

      if (!mounted) return;
      setState(() {
        _course = Map<String, dynamic>.from(results[0] as Map);
        _materials = materials;
        _quizzes = quizzes;
        _doneMaterials = {for (final r in doneMat) r['material_id'].toString()};
        _doneQuizzes = {for (final r in doneQuiz) r['quiz_id'].toString()};
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

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    final d = DateTime.tryParse(raw.toString())?.toLocal();
    if (d == null) return '-';
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${hari[d.weekday - 1]}, ${two(d.day)}-${two(d.month)}-${d.year}';
  }

  /// Item terbuka jika sudah selesai, atau item pertama yang belum selesai.
  /// Item setelahnya terkunci.
  List<_ItemState> _states(List<Map<String, dynamic>> list, Set<String> done) {
    bool openGiven = false;
    return list.map((e) {
      final isDone = done.contains(e['id'].toString());
      var isOpen = false;
      if (!isDone && !openGiven) {
        isOpen = true;
        openGiven = true;
      }
      return _ItemState(isOpen, isDone);
    }).toList();
  }

  Widget _item(
    Map<String, dynamic> data,
    String title,
    String sub, {
    bool open = false,
    bool done = false,
    int index = 0,
  }) {
    final displayTitle = title.trim().isEmpty
        ? (tab == 0 ? 'Materi ${index + 1}' : 'Quiz ${index + 1}')
        : title;

    final card = EduCard(
      borderColor: open ? Ui.blue : (done ? Ui.green : null),
      padding: const EdgeInsets.all(12),
      onTap: open || done
          ? () async {
              await Navigator.pushNamed(
                context,
                tab == 0
                    ? RouteNames.studentMaterialDetail
                    : RouteNames.studentQuiz,
                arguments: {
                  'entity_name': displayTitle,
                  'id': data['id'],
                  'course_id': _courseId,
                },
              );
              // refresh progress setelah kembali dari materi/kuis
              if (mounted) _load();
            }
          : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(sub, style: const TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          if (open || done)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? Ui.greenSoft : Ui.blueSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                done ? Icons.check : Icons.arrow_forward,
                size: 14,
                color: done ? Ui.greenDark : Ui.blue,
              ),
            ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: open || done
          ? card
          : LockedCard(
              text: tab == 0
                  ? 'Selesaikan Modul Sebelumnya'
                  : 'Selesaikan Quiz Sebelumnya',
              child: card,
            ),
    );
  }

  String _safeTitle(
    Map<String, dynamic> data,
    String fallbackPrefix, [
    int index = 0,
  ]) {
    final raw =
        data['title'] ??
        data['name'] ??
        data['course_name'] ??
        data['lesson_name'];

    final text = raw?.toString().trim();
    if (text != null &&
        text.isNotEmpty &&
        text != 'null' &&
        !RegExp(r'^\d+$').hasMatch(text)) {
      return text;
    }
    return '$fallbackPrefix ${index + 1}';
  }

  String _safeSubtitle(Map<String, dynamic> data) {
    final dateValue = data['created_at'] ?? data['scheduled_at'];
    final parsedDate = _formatDate(dateValue);
    if (parsedDate != '-' && parsedDate != 'null') {
      return parsedDate;
    }

    final description = data['description']?.toString().trim();
    if (description != null &&
        description.isNotEmpty &&
        description != 'null') {
      return description;
    }

    if (tab == 0) {
      final qCount = data['question_count'];
      final dMinutes = data['duration_minutes'];
      if (qCount != null || dMinutes != null) {
        return '${qCount ?? 0} Soal | ${dMinutes ?? 0} Menit';
      }
      return 'Belum ada jadwal';
    }

    final qCount = data['question_count'];
    final dMinutes = data['duration_minutes'];
    if (qCount != null || dMinutes != null) {
      return '${qCount ?? 0} Soal | ${dMinutes ?? 0} Menit';
    }
    return 'Belum ada detail quiz';
  }

  List<Widget> _buildList() {
    if (tab == 0) {
      if (_materials.isEmpty) return [_empty('Belum ada materi')];
      final st = _states(_materials, _doneMaterials);
      return [
        for (var i = 0; i < _materials.length; i++)
          _item(
            _materials[i],
            _safeTitle(_materials[i], 'Materi', i),
            _safeSubtitle(_materials[i]),
            open: st[i].open,
            done: st[i].done,
            index: i,
          ),
      ];
    }
    if (_quizzes.isEmpty) return [_empty('Belum ada quiz')];
    final st = _states(_quizzes, _doneQuizzes);
    return [
      for (var i = 0; i < _quizzes.length; i++)
        _item(
          _quizzes[i],
          _safeTitle(_quizzes[i], 'Quiz', i),
          _safeSubtitle(_quizzes[i]),
          open: st[i].open,
          done: st[i].done,
          index: i,
        ),
    ];
  }

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(text, style: const TextStyle(fontSize: 10, color: Ui.muted)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const EduScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _course == null) {
      return EduScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _error ?? 'Data tidak tersedia',
                style: const TextStyle(fontSize: 10, color: Ui.muted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _courseId == null ? null : _load,
                child: const Text('Coba lagi'),
              ),
            ),
          ],
        ),
      );
    }

    final totalMat = _materials.length;
    final doneMat = _doneMaterials.length;
    final progress = totalMat == 0 ? 0 : ((doneMat / totalMat) * 100).round();
    final totalQuiz = _quizzes.length;
    final doneQuiz = _doneQuizzes.length;

    return EduScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackLink(),
          Text(
            _course!['title']?.toString() ?? '-',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          Text(
            _course!['teacher_name']?.toString() ?? '-',
            style: const TextStyle(fontSize: 9),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatBox(value: '$totalMat', label: 'Materi'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(value: '$doneMat/$totalMat', label: 'Berjalan'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(value: '$progress%', label: 'Progress'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _course!['description']?.toString() ?? '',
            style: const TextStyle(fontSize: 9),
          ),
          const SizedBox(height: 10),
          SegTabs(
            labels: const ['Course', 'Quiz'],
            index: tab,
            onChanged: (i) => setState(() => tab = i),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  tab == 0 ? 'Daftar Course' : 'Daftar Quiz',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                tab == 0 ? '$doneMat/$totalMat' : '$doneQuiz/$totalQuiz',
                style: const TextStyle(fontSize: 10, color: Ui.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildList(),
        ],
      ),
    );
  }
}

class _ItemState {
  final bool open;
  final bool done;
  const _ItemState(this.open, this.done);
}
