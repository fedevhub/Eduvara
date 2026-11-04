import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';

class StudentNotificationPage extends StatefulWidget {
  const StudentNotificationPage({super.key});

  @override
  State<StudentNotificationPage> createState() =>
      _StudentNotificationPageState();
}

class _StudentNotificationPageState extends State<StudentNotificationPage> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  bool _isMissingTableError(PostgrestException e) =>
      e.code == 'PGRST205' ||
      e.message.toLowerCase().contains('could not find the table');

  Future<List<Map<String, dynamic>>> _load() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw 'Sesi login berakhir, silakan login ulang';

    try {
      final data = await _db
          .from('notifications')
          .select('id, title, message, created_at')
          .or('user_id.eq.$uid,user_id.is.null')
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
      _items = next;
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

  String _ago(DateTime? d) {
    if (d == null) return '-';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Baru Saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} Menit Lalu';
    if (diff.inHours < 24) return '${diff.inHours} Jam Lalu';
    if (diff.inDays < 7) return '${diff.inDays} Hari Lalu';
    return '${_two(d.day)}-${_two(d.month)}-${d.year}';
  }

  Widget _card(Map<String, dynamic> row, DateTime? date) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: EduCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row['title']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _ago(date),
                style: const TextStyle(fontSize: 7.5, color: Ui.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            row['message']?.toString() ?? '',
            style: const TextStyle(fontSize: 8.5),
          ),
        ],
      ),
    ),
  );

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
    bottom: const EduBottomNav(role: 'student', current: 3),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text(
          'Notification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _items,
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
                  const Text('Notifikasi belum dapat dimuat.'),
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
                  'Belum ada notifikasi.',
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
