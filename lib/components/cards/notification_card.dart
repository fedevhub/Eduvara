import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../core/constants/app_colors.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: notification.read ? Colors.white : AppColors.primarySoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.notifications_none, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                notification.date,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
