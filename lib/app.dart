import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_names.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/materi_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/history_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';

class EduvaraApp extends StatefulWidget {
  const EduvaraApp({super.key});

  @override
  State<EduvaraApp> createState() => _EduvaraAppState();
}

class _EduvaraAppState extends State<EduvaraApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _passwordRecoveryPending = false;
  bool _recoveryDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event != AuthChangeEvent.passwordRecovery) return;
      _passwordRecoveryPending = true;
      _navigatorKey.currentContext?.read<AuthProvider>().setRecoveryPending(
        true,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPasswordRecovery();
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openPasswordRecovery() async {
    if (!_passwordRecoveryPending || _recoveryDialogVisible) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPasswordRecovery();
      });
      return;
    }

    _recoveryDialogVisible = true;
    _navigatorKey.currentContext?.read<AuthProvider>().setRecoveryPending(true);
    navigator.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        _recoveryDialogVisible = false;
        return;
      }
      final updated = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _RecoveryPasswordDialog(),
      );
      _recoveryDialogVisible = false;
      _passwordRecoveryPending = false;
      if (context.mounted) {
        context.read<AuthProvider>().setRecoveryPending(false);
        if (updated == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password berhasil diperbarui.')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => MateriProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Eduvara',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: RouteNames.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

class _RecoveryPasswordDialog extends StatefulWidget {
  const _RecoveryPasswordDialog();

  @override
  State<_RecoveryPasswordDialog> createState() =>
      _RecoveryPasswordDialogState();
}

class _RecoveryPasswordDialogState extends State<_RecoveryPasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() => _error = 'Konfirmasi password tidak sama.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _password.text),
      );
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Gagal memperbarui password: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Buat Password Baru'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password baru'),
        ),
        TextField(
          controller: _confirmation,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Konfirmasi password'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Menyimpan...' : 'Simpan password'),
      ),
    ],
  );
}
