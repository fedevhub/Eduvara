import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final bool positive;
  const StatusBadge({super.key, required this.text, this.positive = true});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: positive ? AppColors.primarySoft : const Color(0xFFFFE9EC),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: positive ? AppColors.primaryDark : AppColors.danger,
      ),
    ),
  );
}
