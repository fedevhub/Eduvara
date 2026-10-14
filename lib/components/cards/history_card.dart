import 'package:flutter/material.dart';
import '../../models/history_model.dart';
import '../../core/constants/app_colors.dart';

class HistoryCard extends StatelessWidget {
  final History history;
  const HistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    leading: const CircleAvatar(
      backgroundColor: AppColors.primarySoft,
      child: Icon(Icons.history, color: AppColors.primary),
    ),
    title: Text(
      history.activity,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(history.date),
    trailing: Text(
      history.status,
      style: const TextStyle(
        color: AppColors.success,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
