import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final kelas = TextEditingController();

  // Label di form -> nilai kolom role di Supabase.
  static const Map<String, String> _roleValues = {
    'Siswa': 'student',
    'Guru': 'teacher',
    'Admin': 'admin',
  };

  String? role; // label: Siswa / Guru / Admin
  bool active = true;

  String? _editingUserId;
  bool _init = false;
  bool _showErrors = false;
  bool _loading = true;
  bool _saving = false;

  // Kolom opsional di tabel profiles. Hanya dipakai jika benar-benar ada.
  Set<String> _columns = {};
  String? _classCol;
  String? _activeCol;
  bool _activeIsBool = true;

  bool get _edit => _editingUserId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_init) return;
    _init = true;

    // Page lain cukup mengirim id pengguna (String) atau Map berisi 'id'.
    // Data lengkapnya selalu diambil ulang dari Supabase.
    final arg = ModalRoute.of(context)?.settings.arguments;

    if (arg is String && arg.isNotEmpty) {
      _editingUserId = arg;
    } else if (arg is Map && arg['id'] != null) {
      _editingUserId = arg['id'].toString();
    }

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      Map<String, dynamic>? sample;

      if (_edit) {
        sample = await _db
            .from('profiles')
            .select()
            .eq('id', _editingUserId!)
            .single();

        name.text = (sample['full_name'] ?? '').toString();

        final value = _roleValues.entries.where(
          (e) => e.value == (sample!['role'] ?? '').toString().toLowerCase(),
        );
        role = value.isEmpty ? null : value.first.key;
      } else {
        // Cek kolom apa saja yang ada di profiles lewat satu baris contoh.
        final rows = await _db.from('profiles').select().limit(1);
        if (rows.isNotEmpty) {
          sample = Map<String, dynamic>.from(rows.first);
        }
      }

      _columns = sample?.keys.toSet() ?? {};

      for (final c in const ['class_name', 'grade_level']) {
        if (_columns.contains(c)) {
          _classCol = c;
          break;
        }
      }

      for (final c in const ['is_active', 'active', 'status']) {
        if (_columns.contains(c)) {
          _activeCol = c;
          break;
        }
      }

      if (sample != null && _classCol != null && _edit) {
        kelas.text = (sample[_classCol] ?? '').toString();
      }

      if (sample != null && _activeCol != null) {
        final raw = sample[_activeCol];
        _activeIsBool = raw is bool || (raw == null && _activeCol != 'status');

        if (_edit) {
          final text = raw?.toString().toLowerCase();
          active = raw == true ||
              text == 'active' ||
              text == 'aktif' ||
              text == 'true';
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[UserForm] Gagal memuat data: $e');

      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Gagal mengambil data pengguna dari Supabase.\n$e');
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    kelas.dispose();
    super.dispose();
  }

  String? _validateName() {
    if (name.text.trim().isEmpty) return 'Nama lengkap wajib diisi';
    return null;
  }

  String? _validateEmail() {
    if (_edit) return null;

    final value = email.text.trim();

    if (value.isEmpty) return 'Email wajib diisi';

    if (!value.contains('@') || !value.contains('.')) {
      return 'Format email tidak valid';
    }

    return null;
  }

  String? _validatePassword() {
    if (_edit) return null;

    if (password.text.isEmpty) return 'Password wajib diisi';
    if (password.text.length < 6) return 'Password minimal 6 karakter';

    return null;
  }

  String? _validateKelas() {
    if (_classCol == null) return null;

    if (kelas.text.trim().isEmpty) {
      return 'Kelas / mata pelajaran wajib diisi';
    }

    return null;
  }

  String? _validateRole() {
    if (role == null) return 'Role wajib dipilih';
    return null;
  }

  Widget _errorText(String? message) {
    if (!_showErrors || message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 3),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Map<String, dynamic> _profileData() {
    final data = <String, dynamic>{
      'full_name': name.text.trim(),
      'role': _roleValues[role],
    };

    if (_classCol != null) {
      data[_classCol!] = kelas.text.trim();
    }

    if (_activeCol != null) {
      data[_activeCol!] =
          _activeIsBool ? active : (active ? 'active' : 'inactive');
    }

    if (!_edit && _columns.contains('email')) {
      data['email'] = email.text.trim();
    }

    return data;
  }

  Future<void> _saveUser() async {
    setState(() => _showErrors = true);

    final hasError = _validateName() != null ||
        _validateEmail() != null ||
        _validatePassword() != null ||
        _validateKelas() != null ||
        _validateRole() != null;

    if (hasError || _saving) return;

    setState(() => _saving = true);

    try {
      if (_edit) {
        await _db
            .from('profiles')
            .update(_profileData())
            .eq('id', _editingUserId!);
      } else {
        await _createUser();
      }

      if (!mounted) return;

      await showSuccessDialog(
        context,
        _edit
            ? 'Pengguna berhasil diperbarui!'
            : 'Pengguna berhasil ditambahkan!',
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } on AuthException catch (e) {
      debugPrint('[UserForm] Auth error: $e');
      _showMessage('Gagal membuat akun: ${e.message}');
    } catch (e) {
      debugPrint('[UserForm] Gagal menyimpan pengguna: $e');

      _showMessage(
        'Gagal menyimpan pengguna ke Supabase. '
        'Periksa nama kolom dan kebijakan RLS.\n$e',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Membuat akun login lewat client terpisah supaya sesi admin yang sedang
  /// login tidak tertimpa oleh akun baru, lalu mengisi data di profiles.
  Future<void> _createUser() async {
    final tempClient = SupabaseClient(_db.supabaseUrl, _db.supabaseKey);

    try {
      final response = await tempClient.auth.signUp(
        email: email.text.trim(),
        password: password.text,
        data: {
          'full_name': name.text.trim(),
          'role': _roleValues[role],
        },
      );

      final user = response.user;

      if (user == null) {
        throw const AuthException('Akun tidak berhasil dibuat.');
      }

      // Email yang sudah terdaftar mengembalikan user tanpa identities.
      if (user.identities != null && user.identities!.isEmpty) {
        throw const AuthException('Email sudah digunakan.');
      }

      // Isi / perbarui baris profiles milik akun baru (memakai sesi admin).
      await _db.from('profiles').upsert({
        'id': user.id,
        ..._profileData(),
      });
    } finally {
      tempClient.dispose();
    }
  }

  Widget _passwordField() {
    return TextField(
      controller: password,
      obscureText: true,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: 'Minimal 6 karakter',
        hintStyle: const TextStyle(fontSize: 11),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: _showErrors && _validatePassword() != null
                ? Ui.red
                : Ui.line,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EduScaffold(
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 6),
            Text(
              _edit ? 'Edit Pengguna' : 'Tambah Pengguna',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              FormCard(
                children: [
                  const FieldLabel('Nama Lengkap', required: true),
                  EduField(
                    controller: name,
                    hint: 'Masukkan nama lengkap',
                    error: _showErrors && _validateName() != null,
                  ),
                  _errorText(_validateName()),

                  // Email & password hanya saat membuat akun baru.
                  if (!_edit) ...[
                    const FieldLabel('Email', required: true),
                    EduField(
                      controller: email,
                      hint: 'nama@eduvara.id',
                      keyboardType: TextInputType.emailAddress,
                      error: _showErrors && _validateEmail() != null,
                    ),
                    _errorText(_validateEmail()),
                    const FieldLabel('Password', required: true),
                    _passwordField(),
                    _errorText(_validatePassword()),
                  ],

                  if (_classCol != null) ...[
                    const FieldLabel('Kelas / Mata Pelajaran', required: true),
                    EduField(
                      controller: kelas,
                      hint: 'Contoh: Kelas 12 RPL',
                      error: _showErrors && _validateKelas() != null,
                    ),
                    _errorText(_validateKelas()),
                  ],

                  const FieldLabel('Role', required: true),
                  EduSelect(
                    hint: 'Pilih role',
                    value: role,
                    items: _roleValues.keys.toList(),
                    error: _showErrors && _validateRole() != null,
                    onChanged: (value) => setState(() => role = value),
                  ),
                  _errorText(_validateRole()),

                  if (_activeCol != null) ...[
                    const FieldLabel('Status', required: true),
                    StatusRadio(
                      active: active,
                      onChanged: (value) => setState(() => active = value),
                    ),
                  ],

                  const SizedBox(height: 18),

                  SolidBtn(
                    label: _saving
                        ? 'Menyimpan...'
                        : _edit
                            ? 'Simpan Perubahan'
                            : 'Tambah Pengguna',
                    onTap: _saveUser,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            const EduFooter(),
          ],
        ),
      ),
    );
  }
}