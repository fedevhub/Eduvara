import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const DangerButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text),
    ),
  );
}
