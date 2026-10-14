import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 58});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Image.asset(
      'assets/images/logo.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}
