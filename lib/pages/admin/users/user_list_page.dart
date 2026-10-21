import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final SupabaseClient _db = Supabase.instance.client;

  // Urutan sama dengan tab: Siswa, Guru, Admin.
  static const List<String> _roles = ['student', 'teacher', 'admin'];

  int tab = 0;
  String query = '';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];

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
      final rows = await _db
          .from('profiles')
          .select()
          .inFilter('role', _roles)
          .order('full_name');

      if (!mounted) return;

      setState(() {
        _users = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      debugPrint('[UserList] Gagal memuat pengguna: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Gagal memuat pengguna dari Supabase.\n$e';
      });
    }
  }

  String _roleOf(Map<String, dynamic> user) =>
      (user['role'] ?? '').toString().toLowerCase();

  int _count(String role) => _users.where((u) => _roleOf(u) == role).length;

  /// Hanya ada jika tabel profiles punya kolom status aktif.
  bool? _activeOf(Map<String, dynamic> user) {
    final value = user['is_active'] ?? user['active'] ?? user['status'];

    if (value == null) return null;
    if (value is bool) return value;

    final text = value.toString().toLowerCase();
    return text == 'active' || text == 'aktif' || text == 'true';
  }

  String _infoOf(Map<String, dynamic> user) {
    final detail = user['class_name'] ?? user['grade_level'];

    if (detail != null && detail.toString().isNotEmpty) {
      return detail.toString();
    }

    return switch (_roleOf(user)) {
      'student' => 'Siswa',
      'teacher' => 'Guru',
      _ => 'Admin',
    };
  }

  List<Map<String, dynamic>> get _visibleUsers {
    final role = _roles[tab];
    final q = query.trim().toLowerCase();

    return _users.where((u) {
      if (_roleOf(u) != role) return false;
      if (q.isEmpty) return true;

      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();

      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _openForm() async {
    final saved = await Navigator.pushNamed(
      context,
      RouteNames.adminUserForm,
    );

    // Form mengembalikan true saat berhasil menyimpan.
    if (saved == true) await _load();
  }

  Future<void> _openDetail(Map<String, dynamic> user) async {
    // Detail cukup menerima id pengguna, data lengkapnya diambil ulang
    // dari Supabase oleh page detail.
    final changed = await Navigator.pushNamed(
      context,
      RouteNames.adminUserDetail,
      arguments: user['id'].toString(),
    );

    // Detail mengembalikan true bila ada perubahan (edit / hapus).
    if (changed == true) await _load();
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
            OutlinedButton(
              onPressed: _load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final users = _visibleUsers;

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

    return Column(
      children: [for (final u in users) _userCard(u)],
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final email = (u['email'] ?? '').toString();
    final active = _activeOf(u);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EduCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        onTap: () => _openDetail(u),
        child: Row(
          children: [
            const DarkAvatar(size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (u['full_name'] ?? 'Tanpa nama').toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: const TextStyle(fontSize: 8, color: Ui.muted),
                    ),
                  Text(
                    _infoOf(u),
                    style: const TextStyle(fontSize: 8, color: Ui.muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (active != null) ...[
                  Pill(
                    active ? 'Aktif' : 'Nonaktif',
                    kind: active ? PillKind.active : PillKind.inactive,
                  ),
                  const SizedBox(height: 6),
                ],
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Ui.muted,
                ),
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
          PageTitle('Manajemen Pengguna', onAdd: _openForm),
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