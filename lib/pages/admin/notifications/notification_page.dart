import 'package:flutter/material.dart';

import '../../../components/navigation/app_bar.dart';
import '../../../components/cards/notification_card.dart';
import '../../../models/notification_model.dart';
import '../../../repositories/notification_repository.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final _repository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _repository.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal memuat notifikasi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EduvaraAppBar(title: 'Notifikasi', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text('Belum ada notifikasi.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return NotificationCard(notification: _notifications[index]);
              },
            ),
    );
  }
}
