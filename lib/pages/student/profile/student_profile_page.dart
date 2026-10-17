import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Ui.bg,
    bottomNavigationBar: const EduBottomNav(role: 'student', current: 4),
    body: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 22),
            decoration: const BoxDecoration(
              gradient: Ui.gradientTop,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.person, size: 34, color: Ui.navy),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fitri Rachmania',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const Text(
                  'fitri123@eduvara.id',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const EduCard(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: [
                      _Row('Role', 'Siswa'),
                      _Row('Status', 'Aktif'),
                      _Row('Kelas', '12 RPL'),
                      _Row('Bergabung', '24 Juli 2024', last: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SoftBtn(
                  label: 'Keluar',
                  icon: Icons.logout,
                  bg: Ui.redTint,
                  fg: Ui.red,
                  height: 38,
                  onTap: () async {
                    final ok = await showConfirmWarning(
                      context,
                      title: 'Keluar dari Eduvara?',
                      primary: 'Ya, Keluar',
                    );
                    if (ok && context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (r) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  final String k;
  final String v;
  final bool last;
  const _Row(this.k, this.v, {this.last = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
    ),
    child: Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
        Text(v, style: const TextStyle(fontSize: 10, color: Ui.muted)),
      ],
    ),
  );
}