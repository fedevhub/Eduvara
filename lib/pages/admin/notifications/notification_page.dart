import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/notifications/notification_widgets.dart';
import '../../../components/ui/kit.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _notifications;
  bool _busy = false;

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
        .select('id, user_id, title, message, created_at, is_read')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _reload() => setState(() => _notifications = _load());

  Future<void> _markAllAsRead() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      if (mounted) setState(() => _notifications = _load());
    } catch (e) {
      debugPrint('[AdminNotifications] gagal menandai semua dibaca: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menandai semua dibaca: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> item) async {
    if (item['is_read'] == true) return;
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', item['id'])
          .eq('user_id', userId);
      if (!mounted) return;
      setState(() {
        item['is_read'] = true;
        _notifications = _load();
      });
    } catch (e) {
      debugPrint('[AdminNotifications] gagal menandai dibaca: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menandai notifikasi dibaca: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotificationHeader(busy: _busy, onMarkAllRead: _markAllAsRead),
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Ui.muted),
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                ],
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
