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
  String? _classFilter;
  String? _majorFilter;
  String _nameOrder = 'Nama A-Z';
  int _pageIndex = 0;
  bool _loading = true;
  String? _error;
  List<UserModel> _users = [];

  static const int _pageSize = 5;
  static const String _allClasses = 'Kelas';
  static const String _allMajors = 'Jurusan';
  static const List<String> _nameOrderOptions = ['Nama A-Z', 'Nama Z-A'];

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
        _pageIndex = 0;
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

  List<UserModel> get _filteredUsers {
    final role = _roles[tab];
    final q = query.trim().toLowerCase();
    final users = _users.where((u) {
      if (u.role != role) return false;
      if (q.isNotEmpty &&
          !u.name.toLowerCase().contains(q) &&
          !u.loginUsername.toLowerCase().contains(q)) {
        return false;
      }
      if (role == 'student') {
        if (_classFilter != null && u.kelas?.trim() != _classFilter) {
          return false;
        }
        if (_majorFilter != null && u.jurusan != _majorFilter) {
          return false;
        }
      }
      return true;
    }).toList();

    users.sort((first, second) {
      final byStatus = (first.isActive ? 0 : 1).compareTo(
        second.isActive ? 0 : 1,
      );
      if (byStatus != 0) return byStatus;
      final byName = first.name.toLowerCase().compareTo(
        second.name.toLowerCase(),
      );
      return _nameOrder == 'Nama Z-A' ? -byName : byName;
    });

    return users;
  }

  List<String> get _classOptions {
    final options =
        _users
            .where((user) => user.role == 'student')
            .map((user) => user.kelas?.trim() ?? '')
            .where((kelas) => kelas.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return options;
  }

  List<String> get _majorOptions {
    final options =
        _users
            .where((user) => user.role == 'student')
            .map((user) => user.jurusan ?? '')
            .where((major) => major.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return options;
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

    final users = _filteredUsers;
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

    final pageCount = (users.length + _pageSize - 1) ~/ _pageSize;
    final pageUsers = users.skip(_pageIndex * _pageSize).take(_pageSize);

    return Column(
      children: [
        for (final u in pageUsers) _userCard(u),
        if (pageCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Halaman sebelumnya',
                onPressed: _pageIndex == 0
                    ? null
                    : () => setState(() => _pageIndex--),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Halaman ${_pageIndex + 1} dari $pageCount',
                style: const TextStyle(fontSize: 11, color: Ui.muted),
              ),
              IconButton(
                tooltip: 'Halaman berikutnya',
                onPressed: _pageIndex + 1 >= pageCount
                    ? null
                    : () => setState(() => _pageIndex++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }

  Widget _filters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Filter siswa',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: EduSelect(
              hint: _allClasses,
              value: _classFilter ?? _allClasses,
              items: [_allClasses, ..._classOptions],
              onChanged: (value) => setState(() {
                _classFilter = value == _allClasses ? null : value;
                _pageIndex = 0;
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: EduSelect(
              hint: _allMajors,
              value: _majorFilter ?? _allMajors,
              items: [_allMajors, ..._majorOptions],
              onChanged: (value) => setState(() {
                _majorFilter = value == _allMajors ? null : value;
                _pageIndex = 0;
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: EduSelect(
              hint: 'Urutkan nama',
              value: _nameOrder,
              items: _nameOrderOptions,
              onChanged: (value) => setState(() {
                _nameOrder = value ?? 'Nama A-Z';
                _pageIndex = 0;
              }),
            ),
          ),
        ],
      ),
    ],
  );

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
                  child: const Icon(Icons.lock_reset, color: Colors.white),
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
              _classFilter = null;
              _majorFilter = null;
              _nameOrder = 'Nama A-Z';
              _pageIndex = 0;
            }),
          ),
          const SizedBox(height: 12),
          SearchBox(
            onChanged: (v) => setState(() {
              query = v;
              _pageIndex = 0;
            }),
          ),
          const SizedBox(height: 12),
          if (tab == 0 && !_loading && _error == null) ...[
            _filters(),
            const SizedBox(height: 12),
          ],
          _content(),
        ],
      ),
    );
  }
}
