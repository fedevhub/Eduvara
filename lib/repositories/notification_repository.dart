import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final rows = await _db
        .from('activity_logs')
        .select(
          'id, actor_role, actor_name, action, entity, entity_name, is_read, created_at',
        )
        .inFilter('actor_role', ['teacher', 'student'])
        .order('created_at', ascending: false)
        .limit(100);

    final activities = List<Map<String, dynamic>>.from(rows);
    final unreadIds = activities
        .where((activity) => activity['is_read'] != true)
        .map((activity) => activity['id'])
        .toList();

    if (unreadIds.isNotEmpty) {
      await _db
          .from('activity_logs')
          .update({'is_read': true})
          .inFilter('id', unreadIds);
    }

    return activities.map((activity) {
      final role = activity['actor_role']?.toString() ?? 'user';
      final actor = activity['actor_name']?.toString() ?? 'Pengguna';
      final action = activity['action']?.toString() ?? '';
      final entity = activity['entity']?.toString() ?? 'aktivitas';
      final entityLabel = switch (entity) {
        'material' => 'materi',
        _ => entity,
      };
      final name = activity['entity_name']?.toString() ?? entity;
      final verb = switch (action) {
        'insert' => 'menambahkan',
        'update' => 'memperbarui',
        'delete' => 'menghapus',
        'complete' => 'menyelesaikan',
        'submit' => 'mengumpulkan',
        _ => 'melakukan aktivitas pada',
      };
      final createdAt = DateTime.tryParse(
        activity['created_at']?.toString() ?? '',
      )?.toLocal();

      return NotificationModel(
        id: activity['id'].toString(),
        title: role == 'teacher' ? 'Aktivitas Teacher' : 'Aktivitas Siswa',
        message: '$actor $verb $entityLabel "$name".',
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
