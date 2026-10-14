import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/routes/route_names.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key});
  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  bool? _active;

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final user = arg is MockUser ? arg : mockSiswa.first;
    final active = _active ?? user.active;

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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 34, color: Ui.navy),
                  ),
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
                    user.email,
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
                        _row('Role', user.role),
                        _row('Status', active ? 'Aktif' : 'Nonaktif'),
                        if (user.role == 'Siswa') _row('Kelas', user.info.replaceFirst('Kelas ', '')),
                        if (user.role == 'Guru') _row('Mapel', user.info),
                        _row('Bergabung', user.joined, last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SoftBtn.edit(
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteNames.adminUserForm,
                            arguments: user,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SoftBtn(
                          label: active ? 'Nonaktifkan' : 'Aktifkan',
                          icon: Icons.shield_outlined,
                          bg: Ui.yellowSoft,
                          fg: Ui.orangeDark,
                          onTap: () => _toggle(user, active),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SoftBtn.delete(onTap: () => _delete(user)),
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

  Future<void> _toggle(MockUser user, bool active) async {
    final ok = await showConfirmWarning(
      context,
      title: active ? 'Nonaktifkan Akun?' : 'Aktifkan Akun?',
      message: active
          ? '${user.name} tidak akan bisa mengakses platform.'
          : '${user.name} akan kembali bisa mengakses platform.',
    );
    if (!ok || !mounted) return;
    setState(() => _active = !active);
    await showSuccessDialog(
      context,
      active ? 'Akun Berhasil di Nonaktifkan' : 'Akun Berhasil di Aktifkan',
    );
  }

  Future<void> _delete(MockUser user) async {
    final ok = await showConfirmDanger(
      context,
      title: 'Hapus Akun?',
      message: '${user.name} akan dihapus dari platform.',
    );
    if (!ok || !mounted) return;
    await showSuccessDialog(context, 'Akun Berhasil di Hapus');
    if (!mounted) return;
    Navigator.pop(context);
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
        Text(v, style: const TextStyle(fontSize: 10, color: Ui.muted)),
      ],
    ),
  );
}
