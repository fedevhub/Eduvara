import 'package:flutter/material.dart';

import '../../../components/ui/kit.dart';
import '../../../core/mock/mock_data.dart';

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final kelas = TextEditingController();

  String? role;
  bool active = true;
  bool _init = false;
  bool _showErrors = false;

  MockUser? _editingUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_init) return;
    _init = true;

    final arg = ModalRoute.of(context)?.settings.arguments;

    if (arg is MockUser) {
      _editingUser = arg;

      name.text = arg.name;
      email.text = arg.email;
      kelas.text = arg.info;
      role = arg.role;
      active = arg.active;
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    kelas.dispose();
    super.dispose();
  }

  String? _validateName() {
    if (name.text.trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }

    return null;
  }

  String? _validateEmail() {
    final value = email.text.trim();

    if (value.isEmpty) {
      return 'Email wajib diisi';
    }

    if (!value.contains('@') || !value.contains('.')) {
      return 'Format email tidak valid';
    }

    final duplicate = allMockUsers.any(
      (user) =>
          user.email.toLowerCase() == value.toLowerCase() &&
          !identical(user, _editingUser),
    );

    if (duplicate) {
      return 'Email sudah digunakan';
    }

    return null;
  }

  String? _validateKelas() {
    if (kelas.text.trim().isEmpty) {
      return 'Kelas / mata pelajaran wajib diisi';
    }

    return null;
  }

  Widget _errorText(String? message) {
    if (!_showErrors || message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 3),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }

  Future<void> _saveUser() async {
    setState(() {
      _showErrors = true;
    });

    final hasError =
        _validateName() != null ||
        _validateEmail() != null ||
        _validateKelas() != null ||
        role == null;

    if (hasError) return;

    final newUser = MockUser(
      name.text.trim(),
      email.text.trim(),
      kelas.text.trim(),
      role!,
      active,
      _editingUser?.joined ?? '13 Oktober 2026',
    );

    if (_editingUser == null) {
      addMockUser(newUser);
    } else {
      updateMockUser(_editingUser!, newUser);
    }

    await showSuccessDialog(
      context,
      _editingUser == null
          ? 'Pengguna berhasil ditambahkan!'
          : 'Pengguna berhasil diperbarui!',
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final edit = _editingUser != null;

    return EduScaffold(
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 6),

            Text(
              edit ? 'Edit Pengguna' : 'Tambah Pengguna',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 12),

            FormCard(
              children: [
                const FieldLabel('Nama Lengkap', required: true),
                EduField(
                  controller: name,
                  hint: 'Masukkan nama lengkap',
                  error: _showErrors && _validateName() != null,
                ),
                _errorText(_validateName()),

                const FieldLabel('Email', required: true),
                EduField(
                  controller: email,
                  hint: 'nama@eduvara.id',
                  keyboardType: TextInputType.emailAddress,
                  error: _showErrors && _validateEmail() != null,
                ),
                _errorText(_validateEmail()),

                const FieldLabel('Kelas / Mata Pelajaran', required: true),
                EduField(
                  controller: kelas,
                  hint: 'Contoh: Kelas 12 RPL',
                  error: _showErrors && _validateKelas() != null,
                ),
                _errorText(_validateKelas()),

                const FieldLabel('Role', required: true),
                EduSelect(
                  hint: 'Pilih role',
                  value: role,
                  items: const ['Siswa', 'Guru', 'Admin'],
                  error: _showErrors && role == null,
                  onChanged: (value) {
                    setState(() {
                      role = value;
                    });
                  },
                ),

                if (_showErrors && role == null)
                  _errorText('Role wajib dipilih'),

                const FieldLabel('Status', required: true),
                StatusRadio(
                  active: active,
                  onChanged: (value) {
                    setState(() {
                      active = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                SolidBtn(
                  label: edit ? 'Simpan Perubahan' : 'Tambah Pengguna',
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
