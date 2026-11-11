import 'package:flutter/material.dart';

import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import 'user_csv_import_dialog.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserRepository _repo = UserRepository();

  // Urutan sama dengan tab: Siswa, Guru, Admin.
  static const List<String> _roles = ['student', 'teacher', 'admin'];

  int tab = 0;
  String query = '';
  bool _loading = true;
  String? _error;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getUsers();
      if (!mounted) return;
      setState(() {
        _users = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[UserList] Gagal memuat: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat pengguna dari Supabase.\n$e';
      });
    }
  }

  int _count(String role) => _users.where((u) => u.role == role).length;

  List<UserModel> get _visible {
    final role = _roles[tab];
    final q = query.trim().toLowerCase();
    return _users.where((u) {
      if (u.role != role) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.loginUsername.toLowerCase().contains(q);
    }).toList();
  }

  String _info(UserModel u) {
    if (u.role == 'student') {
      return (u.kelas?.isNotEmpty ?? false) ? u.kelas! : 'Siswa';
    }
    if (u.role == 'teacher') {
      return (u.mapel?.isNotEmpty ?? false) ? u.mapel! : 'Guru';
    }
    return 'Admin';
  }

  Future<void> _openForm() async {
    final saved = await Navigator.pushNamed(context, RouteNames.adminUserForm);
    if (saved == true) await _load();
  }

  Future<void> _openCsvImport() async {
    final imported = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UserCsvImportDialog(),
    );
    if (imported == true) await _load();
  }

  Future<void> _openPasswordResetRequests() async {
    await Navigator.pushNamed(context, RouteNames.adminPasswordResetRequests);
    if (mounted) await _load();
  }

  Future<void> _openDetail(UserModel u) async {
    await Navigator.pushNamed(
      context,
      RouteNames.adminUserDetail,
      arguments: u.id,
    );
    // Selalu muat ulang, karena detail bisa edit / nonaktifkan / hapus.
    if (mounted) await _load();
  }

  Widget _content() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    final users = _visible;
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Pengguna tidak ditemukan.',
            style: TextStyle(fontSize: 11, color: Ui.muted),
          ),
        ),
      );
    }

    return Column(children: [for (final u in users) _userCard(u)]);
  }

  Widget _userCard(UserModel u) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EduCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        onTap: () => _openDetail(u),
        child: Row(
          children: [
            DarkAvatar(name: u.name, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.name.isEmpty ? 'Tanpa nama' : u.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (u.loginUsername.isNotEmpty)
                    Text(
                      u.loginUsername,
                      style: const TextStyle(fontSize: 8, color: Ui.muted),
                    ),
                  Text(
                    _info(u),
                    style: const TextStyle(fontSize: 8, color: Ui.muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Pill(
                  u.isActive ? 'Aktif' : 'Nonaktif',
                  kind: u.isActive ? PillKind.active : PillKind.inactive,
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, size: 16, color: Ui.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EduScaffold(
      bottom: const EduBottomNav(role: 'admin', current: 1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: PageTitle('Manajemen Pengguna', onAdd: _openForm),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openPasswordResetRequests,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Ui.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openCsvImport,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Ui.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.upload_file, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegTabs(
            labels: [
              'Siswa (${_count('student')})',
              'Guru (${_count('teacher')})',
              'Admin (${_count('admin')})',
            ],
            index: tab,
            onChanged: (i) => setState(() {
              tab = i;
              query = '';
            }),
          ),
          const SizedBox(height: 12),
          SearchBox(onChanged: (v) => setState(() => query = v)),
          const SizedBox(height: 12),
          _content(),
        ],
      ),
    );
  }
}
