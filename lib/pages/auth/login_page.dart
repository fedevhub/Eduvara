import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;
  bool remember = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    await auth.login(
      email.text.isEmpty ? 'admin' : email.text,
      password.text.isEmpty ? '123456' : password.text,
      'admin',
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
  }

  Widget _fieldBox({required IconData icon, required Widget child, Widget? end}) =>
      Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Ui.navy),
            const SizedBox(width: 10),
            Expanded(child: child),
            if (end != null) end,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFA9C2F9), Ui.blue],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo-text.png', width: 150),
                  const SizedBox(height: 2),
                  const Text(
                    'Learn • Grow • Achieve',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Ui.navy,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _fieldBox(
                          icon: Icons.mail,
                          child: TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'admin@gmail.com',
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9AA5B5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _fieldBox(
                          icon: Icons.lock,
                          child: TextField(
                            controller: password,
                            obscureText: hidden,
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: '••••••••••',
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9AA5B5),
                              ),
                            ),
                          ),
                          end: GestureDetector(
                            onTap: () => setState(() => hidden = !hidden),
                            child: Icon(
                              hidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 16,
                              color: Ui.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: remember,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) =>
                                    setState(() => remember = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Remember me',
                              style: TextStyle(fontSize: 9),
                            ),
                            const Spacer(),
                            const Text(
                              'Forget your password?',
                              style: TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => SolidBtn(
                            label: auth.loading ? 'Memproses...' : 'Login',
                            height: 38,
                            radius: 8,
                            onTap: auth.loading ? null : () => _submit(auth),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text.rich(
                    TextSpan(
                      text: 'Dengan masuk, kamu menyetujui ',
                      style: TextStyle(fontSize: 9, color: Colors.white),
                      children: [
                        TextSpan(
                          text: 'Syarat & Ketentuan',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
