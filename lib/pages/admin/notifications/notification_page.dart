import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/navigation/app_bar.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final _supabase = Supabase.instance.client;

  // Nama tabel di Supabase
  static const _table = 'notifications';

  // Jenis notifikasi -> route halaman tujuan.
  // Sesuaikan dengan route yang terdaftar di MaterialApp.
  static const Map<String, String> _routeByType = {
    'peminjaman': '/admin/peminjaman-detail',
    'pengembalian': '/admin/pengembalian-detail',
    'pengguna': '/admin/user-detail',
  };

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('Sesi login tidak ditemukan.');
      }
      final data = await _supabase
          .from(_table)
          .select('id, user_id, title, message, created_at, is_read')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(data);
      final unreadIds = rows
          .where((row) => row['is_read'] != true)
          .map((row) => row['id'])
          .toList();
      if (unreadIds.isNotEmpty) {
        await _supabase
            .from(_table)
            .update({'is_read': true})
            .eq('user_id', userId)
            .inFilter('id', unreadIds);
        for (final row in rows) {
          row['is_read'] = true;
        }
      }

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[AdminNotifications] Gagal memuat notifikasi: $e');
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat notifikasi: $e')));
    }
  }

  // Tandai sudah dibaca (update Supabase + tampilan)
  Future<void> _markAsRead(Map<String, dynamic> row) async {
    if (row['is_read'] == true) return;

    setState(() => row['is_read'] = true);

    try {
      await _supabase
          .from(_table)
          .update({'is_read': true})
          .eq('id', row['id']);
    } catch (e) {
      debugPrint('Gagal update status baca: $e');
      if (mounted) setState(() => row['is_read'] = false);
    }
  }

  // Klik notifikasi: tandai dibaca, lalu buka halaman terkait
  Future<void> _onTapNotification(Map<String, dynamic> row) async {
    await _markAsRead(row);

    if (!mounted) return;

    final route = _routeByType[row['type']];
    if (route == null) return;

    Navigator.pushNamed(context, route, arguments: row['reference_id']);
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';

    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Widget _buildItem(Map<String, dynamic> row) {
    final isRead = row['is_read'] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _onTapNotification(row),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications,
              color: isRead ? Colors.grey : Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['title']?.toString() ?? '-',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(row['message']?.toString() ?? ''),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(row['created_at']),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EduvaraAppBar(title: 'Notifikasi', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
          ? const Center(child: Text('Belum ada notifikasi.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildItem(_rows[index]),
            ),
    );
  }
}
