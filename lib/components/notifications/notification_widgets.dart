import 'package:flutter/material.dart';

import '../ui/kit.dart';

class NotificationHeader extends StatelessWidget {
  final bool busy;
  final VoidCallback onMarkAllRead;

  const NotificationHeader({
    super.key,
    required this.busy,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const BackLink(),
          const Spacer(),
          TextButton(
            onPressed: busy ? null : onMarkAllRead,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              busy ? 'Memproses...' : 'Tandai semua dibaca',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      const Text(
        'Notifikasi',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
    ],
  );
}

class NotificationFeed extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final ValueChanged<Map<String, dynamic>> onTapNotification;

  const NotificationFeed({
    super.key,
    required this.rows,
    required this.onTapNotification,
  });

  DateTime? _date(Map<String, dynamic> row) =>
      DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();

  String _dayLabel(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Hari Ini';
    if (difference == 1) return 'Kemarin';
    return '${date.day.toString().padLeft(2, '0')} - '
        '${date.month.toString().padLeft(2, '0')} - ${date.year}';
  }

  String _relativeDate(DateTime? date) {
    if (date == null) return '-';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Baru Saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} Menit Lalu';
    if (difference.inHours < 24) return '${difference.inHours} Jam Lalu';
    if (difference.inDays < 7) return '${difference.inDays} Hari Lalu';
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Widget _notificationCard(Map<String, dynamic> row) {
    final isRead = row['is_read'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EduCard(
        padding: const EdgeInsets.all(12),
        onTap: isRead ? null : () => onTapNotification(row),
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
                if (!isRead)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.circle, size: 7, color: Ui.blue),
                  ),
                Text(
                  _relativeDate(_date(row)),
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
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Belum ada notifikasi.',
          style: TextStyle(fontSize: 10, color: Ui.muted),
        ),
      );
    }

    final grouped = <Widget>[];
    String? lastLabel;
    for (final row in rows) {
      final label = _dayLabel(_date(row));
      if (label != lastLabel) {
        grouped
          ..add(Text(label, style: const TextStyle(fontSize: 10)))
          ..add(const SizedBox(height: 8));
        lastLabel = label;
      }
      grouped.add(_notificationCard(row));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped,
    );
  }
}
