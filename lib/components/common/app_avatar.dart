import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const AppAvatar({super.key, required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.primarySoft,
    child: Text(
      Formatters.initials(name),
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
