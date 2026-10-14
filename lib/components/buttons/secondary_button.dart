import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const SecondaryButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text),
    ),
  );
}
