import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final rows = await _db
        .from('notifications')
        .select('id, title, message, is_read, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    final notifications = List<Map<String, dynamic>>.from(rows);
    final unreadIds = notifications
        .where((notification) => notification['is_read'] != true)
        .map((notification) => notification['id'])
        .toList();

    if (unreadIds.isNotEmpty) {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .inFilter('id', unreadIds);
    }

    return notifications.map((notification) {
      final createdAt = DateTime.tryParse(
        notification['created_at']?.toString() ?? '',
      )?.toLocal();
      return NotificationModel(
        id: notification['id'].toString(),
        title: notification['title']?.toString() ?? '-',
        message: notification['message']?.toString() ?? '',
        date: _formatDate(createdAt),
        read: true,
      );
    }).toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} • $hour:$minute';
  }
}
