import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/notifications/notification_widgets.dart';
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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<void> _markAllAsRead() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null || _busy) return;

    setState(() => _busy = true);
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);

      if (!mounted) return;
      setState(() {
        _items = _load();
      });
    } catch (e) {
      debugPrint('[StudentNotifications] gagal menandai semua dibaca: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membaca semua notifikasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          .select('id, user_id, title, message, created_at, is_read')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      if (!_isMissingTableError(e)) rethrow;
      return const [];
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> row) async {
    if (row['is_read'] == true) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', row['id'])
          .eq('user_id', uid);
      if (!mounted) return;
      setState(() {
        row['is_read'] = true;
        _items = _load();
      });
    } catch (e) {
      debugPrint('[StudentNotifications] gagal menandai notifikasi dibaca: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menandai notifikasi dibaca: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'student', current: -1),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotificationHeader(busy: _busy, onMarkAllRead: _markAllAsRead),
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
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Notifikasi belum dapat dimuat.',
                  style: TextStyle(fontSize: 10, color: Ui.muted),
                ),
              );
            }
            return NotificationFeed(
              rows: snapshot.data ?? const [],
              onTapNotification: _markAsRead,
            );
          },
        ),
      ],
    ),
  );
}
