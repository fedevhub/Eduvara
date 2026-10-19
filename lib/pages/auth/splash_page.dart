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
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Tampilkan splash screen minimal 1,4 detik.
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // Periksa sesi login yang tersimpan di Supabase.
    await auth.restoreSession();

    if (!mounted) return;

    final user = auth.user;

    // Arahkan pengguna berdasarkan status login dan role.
    final destination = user == null
        ? RouteNames.login
        : RouteNames.dashboardForRole(user.role);

    Navigator.pushReplacementNamed(context, destination);
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
