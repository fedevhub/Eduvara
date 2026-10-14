import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class EduvaraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const EduvaraAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: showBack,
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    ),
    actions: actions,
  );
}
