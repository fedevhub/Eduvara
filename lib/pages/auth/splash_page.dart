import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';
import '../../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      await auth.restoreSession();

      if (!mounted) return;
      if (auth.recoveryPending) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.login,
          (route) => false,
        );
        return;
      }

      final user = auth.user;
      final destination = user == null
          ? RouteNames.login
          : (RouteNames.isStudentRole(user.role)
                ? RouteNames.studentDashboard
                : RouteNames.dashboardForRole(user.role));

      Navigator.pushReplacementNamed(context, destination);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Center(child: Image.asset('assets/images/logo.png', width: 110)),
      ),
    );
  }
}
