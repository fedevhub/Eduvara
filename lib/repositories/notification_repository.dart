import '../models/notification_model.dart';

class NotificationRepository {
  Future<List<NotificationModel>> getNotifications() async => const [
    NotificationModel(
      id: 1,
      title: 'Quiz baru tersedia',
      message: 'Quiz Pengenalan Aljabar sudah dapat dikerjakan.',
      date: 'Hari ini',
    ),
    NotificationModel(
      id: 2,
      title: 'Materi diperbarui',
      message: 'Materi Eksponen telah diperbarui oleh teacher.',
      date: 'Kemarin',
      read: true,
    ),
  ];
}
