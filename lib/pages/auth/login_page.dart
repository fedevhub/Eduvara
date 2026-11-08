import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final emailValue = email.text.trim();
    final passwordValue = password.text;

    if (emailValue.isEmpty || passwordValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi.')),
      );
      return;
    }

    final success = await auth.login(emailValue, passwordValue);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Login gagal.')),
      );
      return;
    }

    final role = auth.user!.role;
    final destination = RouteNames.isStudentRole(role)
        ? RouteNames.studentDashboard
        : RouteNames.dashboardForRole(role);

    Navigator.pushNamedAndRemoveUntil(context, destination, (route) => false);
  }

  Future<void> _showForgotPassword() async {
    final controller = TextEditingController(text: email.text.trim());
    final resetEmail = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lupa Password'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email akun'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kirim tautan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (resetEmail == null || !mounted) return;
    if (resetEmail.isEmpty || !resetEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email akun yang valid.')),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        resetEmail,
        redirectTo: kIsWeb ? Uri.base.origin : 'eduvara://reset-password',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jika email terdaftar, tautan reset password telah dikirim.',
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim tautan reset: ${error.message}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim tautan reset: $error')),
      );
    }
  }

  Widget _fieldBox({
    required IconData icon,
    required Widget child,
    Widget? end,
  }) => Container(
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
              child: SizedBox(
                width: double.infinity,
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final checkbox = SizedBox(
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
                              );
                              const rememberLabel = Text(
                                'Remember me',
                                style: TextStyle(fontSize: 9),
                              );
                              final forgotLabel = InkWell(
                                onTap: _showForgotPassword,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Lupa password?',
                                    style: TextStyle(fontSize: 9),
                                  ),
                                ),
                              );

                              if (constraints.maxWidth < 260) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        checkbox,
                                        const SizedBox(width: 6),
                                        const Expanded(child: rememberLabel),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: forgotLabel,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  checkbox,
                                  const SizedBox(width: 6),
                                  rememberLabel,
                                  const Spacer(),
                                  forgotLabel,
                                ],
                              );
                            },
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
    ),
  );
}
