import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextTheme {
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );
  static const heading = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppColors.text,
  );
  static const muted = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: AppColors.textMuted,
  );
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
