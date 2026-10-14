import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final Timer _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.pushReplacementNamed(context, RouteNames.login);
    });
  }

  @override
  void dispose() {
    _redirectTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFF8FB0F7), Ui.blue],
        ),
      ),
      child: Center(
        child: Image.asset('assets/images/logo.png', width: 110),
      ),
    ),
  );
}
