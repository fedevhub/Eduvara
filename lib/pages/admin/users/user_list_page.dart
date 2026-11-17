import 'package:flutter/material.dart';

import '../../../components/common/student_filter_panel.dart';
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

  static const int _pageSize = 10;
  static const List<String> _studentClassOptions = ['X', 'XI', 'XII'];
  static const List<String> _studentMajorOptions = [
    'RPL A',
    'RPL B',
    'RPL C',
    'RPL D',
    'TKJ A',
    'TKJ B',
    'TKJ C',
    'TKJ D',
    'METRO A',
    'METRO B',
    'ELIN A',
    'ELIN B',
  ];

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

  String? _classValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final upper = raw.trim().toUpperCase();

    final romanMatch = RegExp(r'XII|XI|X').firstMatch(upper);
    if (romanMatch != null) return romanMatch.group(0);

    final numericMatch = RegExp(r'\d+').stringMatch(upper);
    if (numericMatch == null || numericMatch.isEmpty) return null;

    switch (numericMatch) {
      case '10':
        return 'X';
      case '11':
        return 'XI';
      case '12':
        return 'XII';
      default:
        return null;
    }
  }

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
        final classValue = _classValue(u.kelas);
        if (_classFilter != null && classValue != _classFilter) {
          return false;
        }
        if (_majorFilter != null &&
            (u.jurusan ?? '').toUpperCase() != _majorFilter!.toUpperCase()) {
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

  List<String> get _classOptions => List.unmodifiable(_studentClassOptions);

  List<String> get _majorOptions => List.unmodifiable(_studentMajorOptions);

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

  Widget _filters() => StudentFilterPanel(
    classOptions: _classOptions,
    majorOptions: _majorOptions,
    selectedClass: _classFilter,
    selectedMajor: _majorFilter,
    sortOrder: _nameOrder == 'Nama Z-A' ? 'Z-A' : 'A-Z',
    onApply: (selectedClass, selectedMajor, sortOrder) {
      setState(() {
        _classFilter = selectedClass;
        _majorFilter = selectedMajor;
        _nameOrder = sortOrder == 'Z-A' ? 'Nama Z-A' : 'Nama A-Z';
        _pageIndex = 0;
      });
    },
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
