import 'package:flutter/material.dart';

const kBlue = Color(0xFF2563EB);
const kDark = Color(0xFF1E293B);
const kBg = Color(0xFFF8FAFC);
const kGreenBg = Color(0xFFD1FAE5);

const kGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFF93B4F8), kBlue],
  ),
);

List<BoxShadow> get kShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.10),
    blurRadius: 8,
    offset: const Offset(0, 3),
  ),
];

BoxDecoration cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: kShadow,
);
