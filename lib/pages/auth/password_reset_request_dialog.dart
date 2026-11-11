import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/ui/kit.dart';

class PasswordResetRequestDialog extends StatefulWidget {
  final String initialUsername;

  const PasswordResetRequestDialog({super.key, required this.initialUsername});

  @override
  State<PasswordResetRequestDialog> createState() =>
      _PasswordResetRequestDialogState();
}

class _PasswordResetRequestDialogState
    extends State<PasswordResetRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _className = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  bool _passwordVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _username.text = widget.initialUsername;
  }

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _className.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;

  String _errorMessage(dynamic details) {
    final code = details is Map ? details['code']?.toString() : null;
    return switch (code) {
      'request_pending' =>
        'Permintaan reset password akun ini masih menunggu persetujuan admin.',
      'request_rejected' =>
        'Data akun tidak cocok. Periksa kembali username, nama lengkap, dan kelas.',
      'invalid_request' =>
        'Fungsi reset password di server masih versi lama. Admin perlu deploy ulang fungsi password-reset di Supabase.',
      'missing_fields' => 'Username dan nama lengkap wajib diisi.',
      'password_too_short' =>
        'Password minimal 6 karakter. Password boleh lebih panjang.',
      'migration_required' =>
        'Database reset password belum disiapkan. Admin perlu menerapkan migrasi Supabase terlebih dahulu.',
      'server_configuration' =>
        'Konfigurasi fungsi reset password belum lengkap. Hubungi admin.',
      'server_error' =>
        'Server reset password sedang bermasalah. Coba lagi nanti atau hubungi admin.',
      'NOT_FOUND' ||
      'not_found' => 'Fitur reset password belum diaktifkan di server.',
      _ =>
        details is Map
            ? details['message']?.toString() ??
                  'Permintaan reset password gagal diproses. Silakan coba lagi.'
            : 'Permintaan reset password gagal diproses. Silakan coba lagi.',
    };
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'password-reset',
        body: {
          'action': 'request',
          'username': _username.text.trim(),
          'full_name': _fullName.text.trim(),
          'class_name': _className.text.trim(),
          'password': _password.text,
        },
      );
      if (response.status < 200 || response.status >= 300) {
        throw _PasswordResetException(_errorMessage(response.data));
      }
      if (mounted) Navigator.pop(context, true);
    } on FunctionException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error.details);
        _saving = false;
      });
    } on _PasswordResetException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Permintaan reset password gagal diproses: $error';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Ui.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Ui.blueTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lock_reset, color: Ui.blue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ajukan Reset Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Isi data akun untuk mengajukan password baru. Permintaan akan ditinjau admin.',
                  style: TextStyle(color: Ui.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'NISN, NIP, atau username admin',
                    labelStyle: TextStyle(color: Ui.muted),
                    prefixIcon: Icon(Icons.person_outline),
                    prefixIconColor: Ui.blue,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Ui.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Ui.blue, width: 1.5),
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullName,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    labelStyle: TextStyle(color: Ui.muted),
                    prefixIcon: Icon(Icons.badge_outlined),
                    prefixIconColor: Ui.blue,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Ui.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Ui.blue, width: 1.5),
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _className,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Kelas (khusus siswa)',
                    hintText: 'Isi sesuai data kelas yang terdaftar',
                    labelStyle: TextStyle(color: Ui.muted),
                    prefixIcon: Icon(Icons.class_outlined),
                    prefixIconColor: Ui.blue,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Ui.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Ui.blue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('reset-password-field'),
                  controller: _password,
                  obscureText: !_passwordVisible,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Password baru',
                    helperText: 'Minimal 6 karakter; boleh lebih panjang',
                    labelStyle: const TextStyle(color: Ui.muted),
                    helperStyle: const TextStyle(color: Ui.muted),
                    prefixIcon: const Icon(Icons.lock_outline),
                    prefixIconColor: Ui.blue,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Ui.line),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Ui.blue, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      key: const ValueKey('toggle-reset-password-visibility'),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      tooltip: _passwordVisible
                          ? 'Sembunyikan password'
                          : 'Tampilkan password',
                    ),
                  ),
                  validator: (value) => value == null || value.length < 6
                      ? 'Password minimal 6 karakter.'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Ui.redTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Ui.red, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Ui.blue,
            foregroundColor: Colors.white,
          ),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined, size: 18),
          label: Text(_saving ? 'Mengirim...' : 'Ajukan permintaan'),
        ),
      ],
    );
  }
}

class _PasswordResetException implements Exception {
  final String message;

  const _PasswordResetException(this.message);
}
