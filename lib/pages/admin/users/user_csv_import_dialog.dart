import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/csv_parser.dart';
import '../../../repositories/user_repository.dart';

class UserCsvImportDialog extends StatefulWidget {
  const UserCsvImportDialog({super.key});

  @override
  State<UserCsvImportDialog> createState() => _UserCsvImportDialogState();
}

class _UserCsvImportRow {
  final int rowNumber;
  final String name;
  final String email;
  final String password;
  final String role;
  final String? nip;
  final String? mapel;
  final String? kelas;
  final bool active;
  final List<String> errors;
  String? importError;
  bool imported = false;

  _UserCsvImportRow({
    required this.rowNumber,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.nip,
    required this.mapel,
    required this.kelas,
    required this.active,
    required this.errors,
  });

  bool get valid => errors.isEmpty && !imported;
}

class _UserCsvImportDialogState extends State<UserCsvImportDialog> {
  final _repository = UserRepository();
  final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  List<_UserCsvImportRow> _rows = [];
  String? _fileName;
  String? _error;
  bool _loading = false;
  bool _importing = false;
  int _importedCount = 0;

  static const _headerAliases = <String, String>{
    'role': 'role',
    'peran': 'role',
    'nama': 'name',
    'nama_lengkap': 'name',
    'name': 'name',
    'full_name': 'name',
    'email': 'email',
    'password': 'password',
    'kata_sandi': 'password',
    'nip': 'nip',
    'mapel': 'mapel',
    'mata_pelajaran': 'mapel',
    'subject': 'mapel',
    'kelas': 'kelas',
    'class': 'kelas',
    'status': 'status',
  };

  Future<void> _selectFile() async {
    setState(() {
      _loading = true;
      _error = null;
      _rows = [];
      _fileName = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException('Isi file CSV tidak dapat dibaca.');
      }

      final parsed = parseCsv(utf8.decode(bytes));
      if (parsed.length < 2) {
        throw const FormatException(
          'CSV harus berisi header dan minimal satu data.',
        );
      }

      final headers = parsed.first
          .map((header) => _headerAliases[_normalizeHeader(header)] ?? '')
          .toList();
      const requiredHeaders = {'role', 'name', 'email', 'password'};
      final missing = requiredHeaders.difference(headers.toSet());
      if (missing.isNotEmpty) {
        throw FormatException(
          'Kolom wajib tidak ditemukan: ${missing.join(', ')}.',
        );
      }

      final rows = <_UserCsvImportRow>[];
      final emails = <String, List<_UserCsvImportRow>>{};
      for (var index = 1; index < parsed.length; index++) {
        final values = parsed[index];
        final errors = <String>[];
        if (values.length != headers.length) {
          errors.add('Jumlah kolom tidak sesuai header.');
        }
        final fields = <String, String>{};
        for (var column = 0; column < headers.length; column++) {
          final key = headers[column];
          if (key.isNotEmpty) {
            fields[key] = column < values.length ? values[column].trim() : '';
          }
        }

        final roleValue = (fields['role'] ?? '').toLowerCase();
        final role = switch (roleValue) {
          'teacher' || 'guru' => 'teacher',
          'student' || 'siswa' => 'student',
          _ => '',
        };
        final name = fields['name'] ?? '';
        final email = (fields['email'] ?? '').toLowerCase();
        final password = fields['password'] ?? '';
        final nip = fields['nip'];
        final mapel = fields['mapel'];
        final kelas = fields['kelas'];
        final status = (fields['status']?.isNotEmpty ?? false)
            ? fields['status']!.toLowerCase()
            : 'active';
        final active = switch (status) {
          'active' || 'aktif' || 'true' || '1' => true,
          'inactive' || 'nonaktif' || 'false' || '0' => false,
          _ => null,
        };

        if (role.isEmpty) {
          errors.add('Role harus teacher/guru atau student/siswa.');
        }
        if (name.isEmpty) errors.add('Nama lengkap wajib diisi.');
        if (!_emailPattern.hasMatch(email)) {
          errors.add('Format email tidak valid.');
        }
        if (password.length < 6) {
          errors.add('Password minimal 6 karakter.');
        }
        if (role == 'teacher' && (nip == null || nip.isEmpty)) {
          errors.add('NIP wajib diisi untuk guru.');
        }
        if (role == 'teacher' && (mapel == null || mapel.isEmpty)) {
          errors.add('Mata pelajaran wajib diisi untuk guru.');
        }
        if (role == 'student' && (kelas == null || kelas.isEmpty)) {
          errors.add('Kelas wajib diisi untuk siswa.');
        }
        if (active == null) {
          errors.add('Status harus active/aktif atau inactive/nonaktif.');
        }

        final row = _UserCsvImportRow(
          rowNumber: index + 1,
          name: name,
          email: email,
          password: password,
          role: role,
          nip: nip,
          mapel: mapel,
          kelas: kelas,
          active: active ?? true,
          errors: errors,
        );
        if (email.isNotEmpty) emails.putIfAbsent(email, () => []).add(row);
        rows.add(row);
      }

      for (final duplicates in emails.values.where(
        (items) => items.length > 1,
      )) {
        for (final duplicate in duplicates) {
          duplicate.errors.add('Email duplikat di dalam file CSV.');
        }
      }

      final existing = await _repository.getUsers();
      final existingEmails = existing
          .map((user) => user.email.trim().toLowerCase())
          .toSet();
      for (final row in rows) {
        if (existingEmails.contains(row.email)) {
          row.errors.add('Email sudah terdaftar.');
        }
      }

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _fileName = file.name;
        _error = null;
        _importedCount = 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal menyiapkan preview CSV: $e';
        _loading = false;
      });
    }
  }

  String _normalizeHeader(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  Future<void> _importValidRows() async {
    if (_importing) return;
    final pending = _rows.where((row) => row.valid).toList();
    if (pending.isEmpty) return;

    setState(() {
      _importing = true;
      _error = null;
    });

    for (final row in pending) {
      row.importError = null;
      try {
        await _repository.createUser(
          name: row.name,
          email: row.email,
          password: row.password,
          role: row.role,
          active: row.active,
          nip: row.nip,
          mapel: row.mapel,
          kelas: row.kelas,
        );
        row.imported = true;
        _importedCount++;
      } catch (e) {
        row.importError = 'Gagal membuat akun: $e';
      }
      if (mounted) setState(() {});
    }

    if (mounted) setState(() => _importing = false);
  }

  Widget _rowCard(_UserCsvImportRow row) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Baris ${row.rowNumber}: ${row.name.isEmpty ? '(tanpa nama)' : row.name}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '${row.email} • ${row.role.isEmpty ? 'role tidak valid' : row.role}',
          ),
          if (row.imported)
            const Text(
              'Akun berhasil dibuat.',
              style: TextStyle(color: Colors.green),
            )
          else if (row.errors.isNotEmpty || row.importError != null)
            Text(
              [
                ...row.errors,
                if (row.importError != null) row.importError!,
              ].join('\n'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            )
          else
            const Text('Siap diimpor.', style: TextStyle(color: Colors.green)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Import Pengguna dari CSV'),
    content: SizedBox(
      width: 520,
      height: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Header wajib: role, nama_lengkap, email, password. '
            'Guru juga memerlukan nip dan mapel; siswa memerlukan kelas. '
            'Kolom status bersifat opsional dan default-nya active.',
          ),
          const SizedBox(height: 12),
          if (_loading)
            const LinearProgressIndicator()
          else
            OutlinedButton.icon(
              onPressed: _loading || _importing ? null : _selectFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_fileName ?? 'Pilih file CSV'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_rows.length} baris • ${_rows.where((row) => row.errors.isEmpty && !row.imported).length} valid • $_importedCount berhasil',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rows.length,
                itemBuilder: (context, index) => _rowCard(_rows[index]),
              ),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _importing
            ? null
            : () => Navigator.pop(context, _importedCount > 0),
        child: const Text('Selesai'),
      ),
      FilledButton(
        onPressed: _importing || !_rows.any((row) => row.valid)
            ? null
            : _importValidRows,
        child: Text(_importing ? 'Mengimpor...' : 'Import Valid'),
      ),
    ],
  );
}
