import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';

class TeacherHistoryPage extends StatefulWidget {
  const TeacherHistoryPage({super.key});

  @override
  State<TeacherHistoryPage> createState() => _TeacherHistoryPageState();
}

class _TeacherHistoryPageState extends State<TeacherHistoryPage> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _history;

  @override
  void initState() {
    super.initState();
    _history = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final courseRows = await _db
        .from('courses')
        .select('id, title')
        .eq('teacher_id', userId);
    final courseTitles = <String, String>{
      for (final row in courseRows)
        row['id'].toString(): row['title']?.toString() ?? '-',
    };
    if (courseTitles.isEmpty) return const [];

    final courseIds = courseTitles.keys.toList();
    final quizRows = await _db
        .from('quizzes')
        .select('id, course_id, title')
        .inFilter('course_id', courseIds);
    final materialRows = await _db
        .from('materials')
        .select('id, course_id, title')
        .inFilter('course_id', courseIds);

    final quizById = <String, Map<String, dynamic>>{
      for (final row in quizRows) row['id'].toString(): row,
    };
    final materialById = <String, Map<String, dynamic>>{
      for (final row in materialRows) row['id'].toString(): row,
    };
    final quizIds = quizById.keys.toList();
    final materialIds = materialById.keys.toList();

    final attempts = quizIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _db
                .from('quiz_attempts')
                .select('user_id, quiz_id, score, created_at')
                .eq('completed', true)
                .inFilter('quiz_id', quizIds)
                .order('created_at', ascending: false),
          );
    final progress = materialIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _db
                .from('material_progress')
                .select('user_id, material_id, completed_at, created_at')
                .eq('completed', true)
                .inFilter('material_id', materialIds)
                .order('created_at', ascending: false),
          );

    final studentIds = <String>{
      ...attempts.map((row) => row['user_id'].toString()),
      ...progress.map((row) => row['user_id'].toString()),
    }.toList();
    final studentNames = <String, String>{};
    if (studentIds.isNotEmpty) {
      final students = await _db
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', studentIds);
      for (final row in students) {
        studentNames[row['id'].toString()] =
            row['full_name']?.toString() ?? 'Siswa';
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final row in attempts) {
      final quiz = quizById[row['quiz_id'].toString()];
      if (quiz == null) continue;
      result.add({
        'course': courseTitles[quiz['course_id'].toString()] ?? '-',
        'activity': 'Quiz: ${quiz['title'] ?? '-'}',
        'student': studentNames[row['user_id'].toString()] ?? 'Siswa',
        'score': row['score'],
        'created_at': row['created_at'],
      });
    }
    for (final row in progress) {
      final material = materialById[row['material_id'].toString()];
      if (material == null) continue;
      result.add({
        'course': courseTitles[material['course_id'].toString()] ?? '-',
        'activity': 'Materi: ${material['title'] ?? '-'}',
        'student': studentNames[row['user_id'].toString()] ?? 'Siswa',
        'score': null,
        'created_at': row['completed_at'] ?? row['created_at'],
      });
    }
    result.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
      if (aDate == null) return bDate == null ? 0 : 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return result;
  }

  void _reload() => setState(() => _history = _load());

  DateTime? _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal();

  String _two(int value) => value.toString().padLeft(2, '0');

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Hari Ini';
    if (difference == 1) return 'Kemarin';
    return '${_two(date.day)} - ${_two(date.month)} - ${date.year}';
  }

  String _stamp(DateTime? date) => date == null
      ? '-'
      : '${_two(date.day)} - ${_two(date.month)} - ${date.year} | '
            '${_two(date.hour)}.${_two(date.minute)}';

  Widget _activityCard(Map<String, dynamic> item, DateTime? date) {
    final score = item['score'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EduCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['student']?.toString() ?? 'Siswa',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${item['activity']} • ${item['course']}',
                    style: const TextStyle(fontSize: 9),
                  ),
                  const SizedBox(height: 4),
                  Text(_stamp(date), style: const TextStyle(fontSize: 8)),
                ],
              ),
            ),
            if (score != null)
              Container(
                width: 36,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Ui.greenSoft,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Ui.greenDark,
                  ),
                ),
              )
            else
              const Icon(Icons.check_circle, color: Ui.greenDark, size: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivities(List<Map<String, dynamic>> rows) {
    final children = <Widget>[];
    String? lastLabel;
    for (final row in rows) {
      final date = _date(row['created_at']);
      final label = date == null ? '-' : _dayLabel(date);
      if (label != lastLabel) {
        children
          ..add(Text(label, style: const TextStyle(fontSize: 10)))
          ..add(const SizedBox(height: 8));
        lastLabel = label;
      }
      children.add(_activityCard(row, date));
    }
    return children;
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'teacher', current: 3),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text(
          'History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    'History belum dapat dimuat.\n${snapshot.error}',
                    style: const TextStyle(fontSize: 10, color: Ui.muted),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }
            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Belum ada aktivitas siswa.',
                  style: TextStyle(fontSize: 10, color: Ui.muted),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildActivities(rows),
            );
          },
        ),
      ],
    ),
  );
}
