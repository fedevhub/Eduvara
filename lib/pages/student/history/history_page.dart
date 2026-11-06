import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';

class StudentHistoryPage extends StatefulWidget {
  const StudentHistoryPage({super.key});

  @override
  State<StudentHistoryPage> createState() => _StudentHistoryPageState();
}

class _StudentHistoryPageState extends State<StudentHistoryPage> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _history;

  @override
  void initState() {
    super.initState();
    _history = _load();
  }

  bool _isMissingTableError(PostgrestException e) =>
      e.code == 'PGRST205' ||
      e.message.toLowerCase().contains('could not find the table');

  Future<List<Map<String, dynamic>>> _load() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw 'Sesi login berakhir, silakan login ulang';

    try {
      final data = await _db
          .from('quiz_attempts')
          .select(
            'id, score, total_points, created_at, quizzes(title, courses(title))',
          )
          .eq('user_id', uid)
          .eq('completed', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      if (!_isMissingTableError(e)) rethrow;
      return const [];
    }
  }

  void _reload() {
    final next = _load();
    if (!mounted) return;
    setState(() {
      _history = next;
    });
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  DateTime? _date(dynamic raw) =>
      DateTime.tryParse(raw?.toString() ?? '')?.toLocal();

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Kemarin';
    return '${_two(d.day)} - ${_two(d.month)} - ${d.year}';
  }

  String _stamp(DateTime d) =>
      '${_two(d.day)} - ${_two(d.month)} - ${d.year} | ${_two(d.hour)}.${_two(d.minute)}';

  Widget _card(Map<String, dynamic> row, DateTime? date) {
    final quiz = row['quizzes'] as Map?;
    final course = quiz?['courses'] as Map?;
    final courseTitle = course?['title']?.toString() ?? '-';
    final quizTitle = quiz?['title']?.toString() ?? '-';
    final score = row['score'];
    final totalPoints = row['total_points'];
    final scoreText = score is num && totalPoints is num
        ? '${score.round()}/${totalPoints.round()}'
        : score?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EduCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseTitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(quizTitle, style: const TextStyle(fontSize: 8.5)),
                  const SizedBox(height: 4),
                  Text(
                    date == null ? '-' : _stamp(date),
                    style: const TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Ui.greenSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              child: FittedBox(
                child: Text(
                  scoreText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Ui.greenDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroups(List<Map<String, dynamic>> rows) {
    final widgets = <Widget>[];
    String? lastLabel;
    for (final row in rows) {
      final d = _date(row['created_at']);
      final label = d == null ? '-' : _dayLabel(d);
      if (label != lastLabel) {
        widgets.add(Text(label, style: const TextStyle(fontSize: 10)));
        widgets.add(const SizedBox(height: 8));
        lastLabel = label;
      }
      widgets.add(_card(row, d));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'student', current: 2),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text(
          'History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
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
                  const Text('History belum dapat dimuat.'),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Belum ada riwayat quiz.',
                  style: TextStyle(fontSize: 10, color: Ui.muted),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildGroups(rows),
            );
          },
        ),
      ],
    ),
  );
}
