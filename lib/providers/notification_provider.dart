import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository repository = NotificationRepository();
  List<NotificationModel> items = [];
  Future<void> load() async {
    items = await repository.getNotifications();
    notifyListeners();
  }
}
