import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final UserRepository _repo = UserRepository();

  String? _id;
  UserModel? _user;
  bool _init = false;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) {
      _id = arg;
    } else if (arg is Map && arg['id'] != null) {
      _id = arg['id'].toString();
    }
    _load();
  }

  Future<void> _load() async {
    if (_id == null) {
      setState(() {
        _loading = false;
        _error = 'Pengguna tidak ditemukan.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final u = await _repo.getUser(_id!);
      if (!mounted) return;
      setState(() {
        _user = u;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat pengguna.\n$e';
      });
    }
  }

  bool get _isSelf =>
      Supabase.instance.client.auth.currentUser?.id == _user?.id;

  String _date(DateTime? d) => d == null
      ? '-'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _edit() async {
    final saved = await Navigator.pushNamed(
      context,
      RouteNames.adminUserForm,
      arguments: _user!.id,
    );
    if (saved == true) await _load();
  }

  Future<void> _toggle() async {
    final user = _user!;
    if (_isSelf) {
      _msg('Kamu tidak bisa menonaktifkan akunmu sendiri.');
      return;
    }
    final ok = await showConfirmWarning(
      context,
      title: user.isActive ? 'Nonaktifkan Akun?' : 'Aktifkan Akun?',
      message: user.isActive
          ? '${user.name} tidak akan bisa mengakses platform.'
          : '${user.name} akan kembali bisa mengakses platform.',
    );
    if (!ok || !mounted) return;

    try {
      await _repo.setStatus(user.id, !user.isActive);
      await _load();
      if (!mounted) return;
      await showSuccessDialog(
        context,
        user.isActive
            ? 'Akun Berhasil di Nonaktifkan'
            : 'Akun Berhasil di Aktifkan',
      );
    } catch (e) {
      _msg('Gagal mengubah status: $e');
    }
  }

  Future<void> _delete() async {
    final user = _user!;
    if (_isSelf) {
      _msg('Kamu tidak bisa menghapus akunmu sendiri.');
      return;
    }
    final ok = await showConfirmDanger(
      context,
      title: 'Hapus Akun?',
      message: '${user.name} akan dihapus dari platform.',
    );
    if (!ok || !mounted) return;

    try {
      await _repo.deleteUser(user.id);
      if (!mounted) return;
      await showSuccessDialog(context, 'Akun Berhasil di Hapus');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _msg('Gagal menghapus pengguna: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null || _user == null) {
      return EduScaffold(
        bottom: const EduBottomNav(role: 'admin', current: 1),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(_error ?? 'Pengguna tidak ditemukan.'),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ],
        ),
      );
    }

    final user = _user!;
    final active = user.isActive;

    return Scaffold(
      backgroundColor: Ui.bg,
      bottomNavigationBar: const EduBottomNav(role: 'admin', current: 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 8,
                20,
                22,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFF93B4F8), Ui.blue],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BackLink(),
                  ),
                  const SizedBox(height: 4),
                  DarkAvatar(name: user.name, size: 64),
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user.loginUsername,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EduCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Akun',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _row('Username', user.loginUsername),
                        _row('Role', user.roleLabel),
                        _row('Status', active ? 'Aktif' : 'Nonaktif'),
                        if (user.role == 'teacher') ...[
                          _row('Mapel', user.mapel ?? '-'),
                        ],
                        if (user.role == 'student')
                          _row('Kelas', user.kelas ?? '-'),
                        _row('Bergabung', _date(user.createdAt), last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: SoftBtn.edit(onTap: _edit)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SoftBtn(
                          label: active ? 'Nonaktifkan' : 'Aktifkan',
                          icon: Icons.shield_outlined,
                          bg: Ui.yellowSoft,
                          fg: Ui.orangeDark,
                          onTap: _toggle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SoftBtn.delete(onTap: _delete),
                  const SizedBox(height: 60),
                  const EduFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool last = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: Ui.muted),
          ),
        ),
      ],
    ),
  );
}
