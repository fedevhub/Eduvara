import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import '../courses/course_form_page.dart' show SubjectSelector;

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final UserRepository _repo = UserRepository();

  final name = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final kelas = TextEditingController();

  static const Map<String, String> _roleValues = {
    'Siswa': 'student',
    'Guru': 'teacher',
    'Admin': 'admin',
  };

  String? mapel;

  String? roleLabel;
  bool active = true;

  String? _editingId;
  UserModel? _old;
  bool _init = false;
  bool _showErrors = false;
  bool _loading = false;
  bool _saving = false;

  bool get _edit => _editingId != null;
  String? get _role => roleLabel == null ? null : _roleValues[roleLabel];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && arg.isNotEmpty) {
      _editingId = arg;
    } else if (arg is Map && arg['id'] != null) {
      _editingId = arg['id'].toString();
    }

    if (_edit) _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final u = await _repo.getUser(_editingId!);
      _old = u;
      name.text = u.name;
      username.text = u.loginUsername;
      mapel = (u.mapel?.isNotEmpty ?? false) ? u.mapel : null;
      kelas.text = u.kelas ?? '';
      active = u.isActive;
      roleLabel = _roleValues.entries
          .firstWhere(
            (e) => e.value == u.role,
            orElse: () => const MapEntry('Siswa', 'student'),
          )
          .key;
    } catch (e) {
      debugPrint('[UserForm] Gagal memuat: $e');
      _showMessage('Gagal mengambil data pengguna.\n$e');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    password.dispose();
    kelas.dispose();
    super.dispose();
  }

  String? _vName() =>
      name.text.trim().isEmpty ? 'Nama lengkap wajib diisi' : null;

  String? _vPassword() {
    final v = password.text;
    if (!_edit && v.isEmpty) return 'Password wajib diisi';
    if (v.isNotEmpty && v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String? _vRole() => _role == null ? 'Role wajib dipilih' : null;

  String? _vUsername() =>
      username.text.trim().isEmpty ? 'Username wajib diisi' : null;

  String? _vMapel() => _role == 'teacher' && (mapel == null || mapel!.isEmpty)
      ? 'Mata pelajaran wajib dipilih'
      : null;

  String? _vKelas() => _role == 'student' && kelas.text.trim().isEmpty
      ? 'Kelas wajib diisi'
      : null;

  Widget _err(String? message) {
    if (!_showErrors || message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    setState(() => _showErrors = true);

    final hasError = [
      _vName(),
      _vUsername(),
      _vPassword(),
      _vRole(),
      _vMapel(),
      _vKelas(),
    ].any((e) => e != null);

    if (hasError || _saving) return;
    setState(() => _saving = true);

    try {
      if (_edit) {
        await _repo.updateUser(
          old: _old!,
          name: name.text.trim(),
          username: username.text.trim(),
          role: _role!,
          active: active,
          mapel: mapel,
          kelas: kelas.text.trim(),
        );
      } else {
        await _repo.createUser(
          name: name.text.trim(),
          username: username.text.trim(),
          password: password.text,
          role: _role!,
          active: active,
          mapel: mapel,
          kelas: kelas.text.trim(),
        );
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
      _showMessage('Gagal membuat akun: ${e.message}');
    } on PostgrestException catch (e) {
      debugPrint('[UserForm] DB error: $e');
      _showMessage('Gagal menyimpan ke Supabase: ${e.message}');
    } catch (e) {
      debugPrint('[UserForm] Error: $e');
      _showMessage('Gagal menyimpan pengguna.\n$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EduScaffold(
      body: Column(
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
                const FieldLabel('Nama Lengkap'),
                EduField(
                  controller: name,
                  hint: 'Masukkan nama lengkap',
                  error: _showErrors && _vName() != null,
                ),
                _err(_vName()),

                const FieldLabel('Username'),
                EduField(
                  controller: username,
                  hint: switch (_role) {
                    'student' => 'Masukkan NISN siswa',
                    'teacher' => 'Masukkan NIP guru',
                    'admin' => 'Tentukan username admin',
                    _ => 'Pilih role, lalu masukkan username',
                  },
                  error: _showErrors && _vUsername() != null,
                ),
                _err(_vUsername()),

                if (!_edit) ...[
                  const FieldLabel('Password'),
                  EduField(
                    controller: password,
                    hint: 'Minimal 6 karakter',
                    error: _showErrors && _vPassword() != null,
                  ),
                  _err(_vPassword()),
                ],

                const FieldLabel('Role'),
                EduSelect(
                  hint: 'Pilih role',
                  value: roleLabel,
                  items: _roleValues.keys.toList(),
                  error: _showErrors && _vRole() != null,
                  onChanged: (v) => setState(() => roleLabel = v),
                ),
                _err(_vRole()),

                // Guru: username adalah NIP.
                if (_role == 'teacher') ...[
                  const FieldLabel('Mata Pelajaran'),
                  SubjectSelector(
                    hint: 'Pilih mata pelajaran',
                    value: mapel,
                    extraSubjects: mapel == null ? const [] : [mapel!],
                    error: _showErrors && _vMapel() != null,
                    onChanged: (v) => setState(() => mapel = v),
                  ),
                  _err(_vMapel()),
                ],

                // Siswa: Kelas
                if (_role == 'student') ...[
                  const FieldLabel('Kelas'),
                  EduField(
                    controller: kelas,
                    hint: 'Contoh: 12 RPL A',
                    error: _showErrors && _vKelas() != null,
                  ),
                  _err(_vKelas()),
                ],

                const FieldLabel('Status'),
                StatusRadio(
                  active: active,
                  onChanged: (v) => setState(() => active = v),
                ),

                const SizedBox(height: 18),
                SolidBtn(
                  label: _saving
                      ? 'Menyimpan...'
                      : _edit
                      ? 'Edit Pengguna'
                      : 'Tambah Pengguna',
                  onTap: _saving ? null : _save,
                ),
              ],
            ),
          const SizedBox(height: 24),
          const EduFooter(),
        ],
      ),
    );
  }
}
