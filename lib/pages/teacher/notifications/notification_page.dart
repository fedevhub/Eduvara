import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';

class TeacherNotificationPage extends StatefulWidget {
  const TeacherNotificationPage({super.key});

  @override
  State<TeacherNotificationPage> createState() =>
      _TeacherNotificationPageState();
}

class _TeacherNotificationPageState extends State<TeacherNotificationPage> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final rows = await _db
        .from('notifications')
        .select('id, title, message, created_at, is_read')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final items = List<Map<String, dynamic>>.from(rows);
    final unreadIds = items
        .where((item) => item['is_read'] != true)
        .map((item) => item['id'])
        .toList();
    if (unreadIds.isNotEmpty) {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .inFilter('id', unreadIds);
      for (final item in items) {
        item['is_read'] = true;
      }
    }
    return items;
  }

  void _reload() => setState(() => _notifications = _load());

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '-';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        const SizedBox(height: 4),
        const Text(
          'Notifikasi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _notifications,
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
                    'Notifikasi belum dapat dimuat.\n${snapshot.error}',
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

            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Belum ada notifikasi.',
                  style: TextStyle(fontSize: 10, color: Ui.muted),
                ),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  Padding(
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
                                  item['title']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                _date(item['created_at']),
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Ui.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item['message']?.toString() ?? '',
                            style: const TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
